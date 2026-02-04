#!/bin/bash

# 定义变量
BINARY_NAME="gpt-load-linux-arm64"
REPO_API="https://api.github.com/repos/tbphp/gpt-load/releases/latest"
CERT_PATH="$PREFIX/etc/tls/cert.pem"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 停止服务函数
stop_service() {
    echo -e "${YELLOW}正在停止服务...${NC}"
    PID=$(pgrep -f "$BINARY_NAME")
    if [ -n "$PID" ]; then
        kill "$PID"
        echo -e "${GREEN}服务已停止 (PID: $PID)${NC}"
    else
        echo -e "${YELLOW}未发现正在运行的服务。${NC}"
    fi
}

# 检查证书函数
check_cert() {
    if [ ! -f "$CERT_PATH" ]; then
        echo -e "${RED}错误: 根证书不存在 ($CERT_PATH)${NC}"
        read -p "是否自动安装 ca-certificates? (y/n): " confirm
        if [[ "$confirm" == [yY] ]]; then
            pkg install ca-certificates -y
        else
            echo -e "${YELLOW}请手动安装证书后重试。${NC}"
        fi
    else
        echo -e "${GREEN}根证书已就绪。${NC}"
    fi
}

# 配置环境菜单
config_env_menu() {
    while true; do
        echo -e "\n--- 配置环境 ---"
        echo "1. 检查/安装根证书"
        echo "2. 更新系统软件包 (pkg update && upgrade)"
        echo "3. 返回主菜单"
        read -p "请选择 [1-3]: " env_choice
        case $env_choice in
            1) check_cert ;;
            2) pkg update && pkg upgrade -y ;;
            3) break ;;
            *) echo -e "${RED}无效选择${NC}" ;;
        esac
    done
}

# 版本更新函数
update_version() {
    stop_service
    echo -e "${YELLOW}正在检查最新版本信息...${NC}"
    
    # 检查是否安装了 jq
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}需要安装 jq 来解析版本信息，正在尝试安装...${NC}"
        pkg install jq -y
    fi

    # 获取最新的下载链接
    LATEST_URL=$(curl -s "$REPO_API" | jq -r ".assets[] | select(.name == \"$BINARY_NAME\") | .browser_download_url")

    if [ -z "$LATEST_URL" ] || [ "$LATEST_URL" == "null" ]; then
        echo -e "${RED}无法获取下载链接，可能是 API 限制或网络问题。${NC}"
        return 1
    fi

    echo -e "${YELLOW}正在下载: $LATEST_URL${NC}"
    curl -L "$LATEST_URL" -o "$BINARY_NAME"
    
    if [ $? -eq 0 ]; then
        chmod +x "$BINARY_NAME"
        echo -e "${GREEN}版本更新成功！${NC}"
    else
        echo -e "${RED}下载失败，请检查网络。${NC}"
    fi
}

# 启动服务函数
start_service() {
    if [ ! -f "./$BINARY_NAME" ]; then
        echo -e "${RED}错误: 未找到可执行文件 $BINARY_NAME${NC}"
        echo -e "${YELLOW}请先进行版本更新以获取文件。${NC}"
        return
    fi
    
    check_cert
    if [ ! -f "$CERT_PATH" ]; then
        echo -e "${RED}启动失败: 证书缺失。${NC}"
        return
    fi

    echo -e "${YELLOW}正在启动服务...${NC}"
    chmod +x "$BINARY_NAME"
    export SSL_CERT_FILE="$CERT_PATH"
    nohup "./$BINARY_NAME" > /dev/null 2>&1 &
    
    sleep 2
    PID=$(pgrep -f "$BINARY_NAME")
    if [ -n "$PID" ]; then
        echo -e "${GREEN}服务已成功启动！(PID: $PID)${NC}"
    else
        echo -e "${RED}服务启动失败，请检查日志。${NC}"
    fi
}

# 启动脚本时的检查
if [ ! -f "./$BINARY_NAME" ]; then
    echo -e "${YELLOW}提示: 当前目录未发现 $BINARY_NAME${NC}"
    read -p "是否现在下载最新版本? (y/n): " init_download
    if [[ "$init_download" == [yY] ]]; then
        update_version
    fi
fi

# 主菜单
while true; do
    echo -e "\n${GREEN}=== gpt-load 管理脚本 (Termux) ===${NC}"
    echo "1. 配置环境"
    echo "2. 版本更新"
    echo "3. 启动服务"
    echo "4. 停止服务"
    echo "5. 退出脚本"
    read -p "请选择操作 [1-5]: " main_choice

    case $main_choice in
        1) config_env_menu ;;
        2) update_version ;;
        3) start_service ;;
        4) stop_service ;;
        5) echo "退出脚本。"; exit 0 ;;
        *) echo -e "${RED}无效选择，请输入 1-5${NC}" ;;
    esac
done

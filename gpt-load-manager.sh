#!/bin/bash
# ==============================================================================
# gpt-load - Termux Management Script
# ==============================================================================

# --- 用于彩色输出的辅助函数 ---
setup_colors() {
  if [ -t 1 ]; then
    RED=$(printf '\033[0;31m')
    GREEN=$(printf '\033[0;32m')
    YELLOW=$(printf '\033[0;33m')
    BLUE=$(printf '\033[0;34m')
    BOLD=$(printf '\033[1m')
    NC=$(printf '\033[0m')
  else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NC=""
  fi
}

# --- 全局变量 ---
WORK_DIR="gpt-load"
BINARY_NAME="gpt-load-linux-arm64"
BINARY_PATH="${WORK_DIR}/${BINARY_NAME}"
REPO_API="https://api.github.com/repos/tbphp/gpt-load/releases/latest"
ENV_REPO_API="https://api.github.com/repos/LiquorXR/gpt-load-manager/contents/.env.example"
CERT_PATH="$PREFIX/etc/tls/cert.pem"


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
        echo -e "\n${BLUE}--- 配置环境 ---${NC}"
        echo -e "  ${BOLD}[1]${NC} 检查/安装根证书"
        echo -e "  ${BOLD}[2]${NC} 更新系统软件包 (pkg update && upgrade)"
        echo -e "  ${BOLD}[3]${NC} 返回主菜单"
        read -p "请选择 [1-3]: " env_choice < /dev/tty
        case $env_choice in
            1) check_cert ;;
            2)
                read -p "是否确定要执行系统软件包更新? (y/N): " confirm_pkg < /dev/tty
                if [[ "$confirm_pkg" == [yY] ]]; then
                    echo -e "${BLUE}正在更新系统软件包...${NC}" && pkg update && pkg upgrade -y
                else
                    echo -e "${YELLOW}已取消更新。${NC}"
                fi
                ;;
            3) break ;;
            *) echo -e "${RED}无效选择${NC}" ;;
        esac
    done
}

# 版本更新核心逻辑
do_update_version() {
    echo -e "\n${BLUE}正在更新应用版本...${NC}"
    
    # 如果有后台运行的旧进程，尝试清理
    local PIDS=$(pgrep -f "$BINARY_NAME")
    if [ -n "$PIDS" ]; then
        echo -e "${YELLOW}正在清理正在运行的进程...${NC}"
        kill $PIDS 2>/dev/null || true
    fi

    # 创建工作目录
    mkdir -p "$WORK_DIR"
    
    echo -e "${BLUE}正在检查最新版本信息...${NC}"
    
    # 检查是否安装了 jq
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}需要安装 jq 来解析版本信息，正在尝试安装...${NC}"
        pkg install jq -y
    fi

    # 获取最新的下载链接
    LATEST_URL=$(curl -s "$REPO_API" | jq -r ".assets[] | select(.name == \"$BINARY_NAME\") | .browser_download_url")

    if [ -z "$LATEST_URL" ] || [ "$LATEST_URL" == "null" ]; then
        echo -e "${RED}错误: 无法获取下载链接，可能是 API 限制或网络问题。${NC}"
        return 1
    fi

    echo -e "${BLUE}正在下载: $LATEST_URL${NC}"
    curl -L -o "${BINARY_PATH}" "$LATEST_URL"
    
    if [ $? -eq 0 ]; then
        chmod +x "${BINARY_PATH}"
        echo -e "${GREEN}版本更新成功！${NC}"
    else
        echo -e "${RED}下载失败，请检查网络。${NC}"
    fi
}

# 版本更新函数 (带确认)
update_version() {
    read -p "是否确定要检查并下载最新应用版本? (y/N): " confirm_update < /dev/tty
    if [[ "$confirm_update" == [yY] ]]; then
        do_update_version
    else
        echo -e "${YELLOW}已取消更新。${NC}"
    fi
}

# 检查/下载 .env 配置文件函数
check_env_file() {
    if [ ! -f "$WORK_DIR/.env" ]; then
        echo -e "${YELLOW}未发现 .env 配置文件，正在从 GitHub API 获取...${NC}"
        
        # 检查是否安装了 jq
        if ! command -v jq &> /dev/null; then
            echo -e "${YELLOW}需要安装 jq 来解析 API 响应，正在尝试安装...${NC}"
            pkg install jq -y
        fi

        # 通过 GitHub API 获取文件下载链接
        ENV_DOWNLOAD_URL=$(curl -s "$ENV_REPO_API" | jq -r ".download_url")

        if [ -z "$ENV_DOWNLOAD_URL" ] || [ "$ENV_DOWNLOAD_URL" == "null" ]; then
            echo -e "${RED}无法获取 .env.example 下载链接，可能是 API 限制或网络问题。${NC}"
            return 1
        fi

        curl -s "$ENV_DOWNLOAD_URL" -o "$WORK_DIR/.env"
        
        if [ $? -eq 0 ] && [ -f "$WORK_DIR/.env" ]; then
            echo -e "${GREEN}.env 配置文件已下载成功！${NC}"
            echo -e "${YELLOW}请根据需要修改 $WORK_DIR/.env 文件中的配置项。${NC}"
        else
            echo -e "${RED}.env 文件下载失败，请手动创建。${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}.env 配置文件已存在。${NC}"
    fi
}

# 启动服务函数
start_service() {
    if [ ! -f "${BINARY_PATH}" ]; then
        echo -e "${RED}错误: 未找到 '${BINARY_PATH}' 可执行文件。${NC}"
        read -p "是否立即下载最新版本? (Y/n): " confirm < /dev/tty
        if [[ "$confirm" == "y" || "$confirm" == "Y" || "$confirm" == "" ]]; then
            do_update_version
        else
            echo -e "${YELLOW}用户取消操作，返回主菜单。${NC}"
            return 1
        fi
    fi
    
    check_cert
    if [ ! -f "$CERT_PATH" ]; then
        echo -e "${RED}启动失败: 证书缺失。${NC}"
        return 1
    fi

    check_env_file

    echo -e "\n${GREEN}===================================================${NC}"
    echo -e "${GREEN}${BOLD}启动 gpt-load 服务...${NC}"
    echo -e "${GREEN}===================================================${NC}"
    echo -e "\n${YELLOW}提示: 按 ${BOLD}Ctrl+C${NC} 组合键来停止服务。${NC}\n"

    # 设置环境变量
    export SSL_CERT_FILE="$CERT_PATH"
    
    # 切换到应用目录并执行
    (cd "${WORK_DIR}" && "./${BINARY_NAME}")
}

# --- 主菜单 ---
show_main_menu() {
  while true; do
    clear # 清屏以获得更好的视觉效果
    echo -e "${GREEN}   ██████╗ ██████╗ ████████╗      ██╗      ██████╗  █████╗ ██████╗ ${NC}"
    echo -e "${GREEN}  ██╔════╝ ██╔══██╗╚══██╔══╝      ██║     ██╔═══██╗██╔══██╗██╔══██╗${NC}"
    echo -e "${GREEN}  ██║  ███╗██████╔╝   ██║         ██║     ██║   ██║███████║██║  ██║${NC}"
    echo -e "${GREEN}  ██║   ██║██╔═══╝    ██║         ██║     ██║   ██║██╔══██║██║  ██║${NC}"
    echo -e "${GREEN}  ╚██████╔╝██║        ██║         ███████╗╚██████╔╝██║  ██║██████╔╝${NC}"
    echo -e "${GREEN}   ╚═════╝ ╚═╝        ╚═╝         ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ${NC}"
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "           ${BOLD}gpt-load Manager for Termux v0.16${NC}"
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "  ${BOLD}[1]${NC} ${GREEN}启动服务${NC}  --- 启动 gpt-load 代理服务"
    echo -e "  ${BOLD}[2]${NC} ${BLUE}配置环境${NC}  --- 检查证书和系统更新"
    echo -e "  ${BOLD}[3]${NC} ${YELLOW}版本更新${NC}  --- 下载最新的可执行文件"
    echo -e "  ${BOLD}[0]${NC} ${RED}退出脚本${NC}  --- 关闭管理脚本"
    echo -e "${BLUE}=========================================================${NC}"
    read -p "请输入选项 [0-3]: " menu_choice < /dev/tty

    case $menu_choice in
      1)
        start_service || true
        echo -e "\n${YELLOW}服务已停止。${NC}"
        read -p "按任意键返回主菜单..." -n 1 -s < /dev/tty
        ;;
      2)
        config_env_menu || true
        read -p $'\n'"按任意键返回主菜单..." -n 1 -s < /dev/tty
        ;;
      3)
        update_version || true
        read -p $'\n'"按任意键返回主菜单..." -n 1 -s < /dev/tty
        ;;
      0)
        echo "正在退出脚本。"
        exit 0
        ;;
      *)
        echo -e "${RED}无效选项，请输入 0-3 之间的数字。${NC}"
        sleep 2
        ;;
    esac
  done
}

# --- 脚本执行入口 ---
main() {
  setup_colors

  # 确保工作目录存在
  mkdir -p "${WORK_DIR}"

  # 进入主菜单
  show_main_menu
}

main "$@"

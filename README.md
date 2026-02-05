# GPT-Load Manager

`GPT-Load Manager` 是一个跨平台的自动化管理脚本工具，专门用于部署、管理和更新 [gpt-load](https://github.com/tbphp/gpt-load) 代理服务。它支持 Windows 环境以及 Android 上的 Termux 环境。

## 🚀 核心功能

- **自动化部署**：自动从 GitHub 下载最新版本的 `gpt-load` 可执行文件。
- **环境配置**：
  - **Windows**: 自动检查后台服务状态、监听地址和版本信息。
  - **Termux**: 自动管理根证书（CA-Certificates）以确保网络请求安全。
- **配置管理**：一键获取 `.env` 配置文件模板，支持快捷编辑和重置。
- **服务控制**：支持一键启动、停止和后台运行代理服务。
- **版本维护**：自动检测并下载 GitHub 上的最新 Release 版本。
- **日志查看**：集成日志查看功能，方便调试和监控运行状态。

## 📂 项目结构

```text
gpt-load-manager/
├── gpt-load-manager.bat    # Windows 环境管理脚本 (PowerShell 驱动)
├── gpt-load-manager.sh     # Termux 环境管理脚本 (Bash 驱动)
├── .env.example            # 配置文件模板
├── .gitignore              # Git 忽略配置
└── gpt-load/               # (运行后生成) 存放核心程序与配置的目录
```

## 🛠️ 安装与使用

### 1. Windows 环境

1. 下载项目到本地。
2. 双击运行 `gpt-load-manager.bat`。
3. 按照菜单提示选择：
   - `[1]` 启动服务（首次运行会自动下载程序和配置）。
   - `[4]` 修改配置文件，填入你的代理参数。

### 2. Android (Termux) 环境

1. 在 Termux 中克隆或下载脚本。
2. 授予执行权限：
   ```bash
   chmod +x gpt-load-manager.sh
   ```
3. 运行脚本：
   ```bash
   ./gpt-load-manager.sh
   ```
4. 在菜单中选择 `[1]` 启动服务。脚本会自动处理证书和二进制文件的下载。

## ⚙️ 配置说明

程序运行依赖于 `.env` 文件。首次启动时，脚本会自动从 GitHub 获取最新的 `.env.example`。

主要配置项通常包括：
- 代理监听端口
- 上游 GPT 接口地址
- 认证信息等

## 📜 许可证

本项目基于 MIT 许可证开源。

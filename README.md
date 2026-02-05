# GPT-Load Manager

[中文版](./README_CN.md)

`GPT-Load Manager` is a cross-platform automation script toolkit designed to deploy, manage, and update the [gpt-load](https://github.com/tbphp/gpt-load) proxy service. It supports both Windows environments and Termux on Android.

## 🚀 Key Features

- **Automated Deployment**: Automatically downloads the latest version of the `gpt-load` executable from GitHub.
- **Environment Configuration**:
  - **Windows**: Automatically checks background service status, listening addresses, and version information.
  - **Termux**: Manages root certificates (CA-Certificates) to ensure secure network requests.
- **Configuration Management**: One-click acquisition of `.env` configuration templates, with support for quick editing and resetting.
- **Service Control**: Simple commands to start, stop, and run the proxy service in the background.
- **Version Maintenance**: Detects and downloads the latest release from GitHub automatically.
- **Log Viewing**: Integrated log viewing functionality for easy debugging and monitoring.

## 📂 Project Structure

```text
gpt-load-manager/
├── gpt-load-manager.bat    # Windows management script (PowerShell driven)
├── gpt-load-manager.sh     # Termux management script (Bash driven)
├── .env.example            # Configuration template
├── .gitignore              # Git ignore configuration
└── gpt-load/               # (Generated at runtime) Directory for core program and config
```

## 🛠️ Installation & Usage

### 1. Windows Environment

1. Download the project to your local machine.
2. Double-click `gpt-load-manager.bat` to run.
3. Follow the menu prompts:
   - `[1]` Start Service (The script will auto-download the binary and config on first run).
   - `[4]` Edit Configuration to input your proxy parameters.

### 2. Android (Termux) Environment

1. Clone or download the script in Termux.
2. Grant execution permissions:
   ```bash
   chmod +x gpt-load-manager.sh
   ```
3. Run the script:
   ```bash
   ./gpt-load-manager.sh
   ```
4. Select `[1]` from the menu to start the service. The script handles certificate and binary downloads automatically.

## ⚙️ Configuration

The application relies on a `.env` file. Upon the first startup, the script will automatically fetch the latest `.env.example` from GitHub.

Key configuration items typically include:
- Proxy listening port
- Upstream GPT API address
- Authentication credentials, etc.

## 📜 License

This project is open-sourced under the MIT License.

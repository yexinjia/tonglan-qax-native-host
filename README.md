# tonglan-qax-native-host

为浏览器扩展 **「通览·跳转奇安信浏览器」** 安装本机 **Native Host**（**macOS / Windows**）。

商店只能安装扩展本身，**不能**自动写入系统脚本。扩展要调用奇安信浏览器（Qaxbrowser），必须先在本机安装本仓库提供的 Native Host。

仓库地址：<https://github.com/yexinjia/tonglan-qax-native-host>

## 你需要什么

- **macOS** 或 **Windows（Win10 及以上，含更新版本）**
- 已安装奇安信浏览器（Qaxbrowser）
- 已从 Firefox / Chrome 插件市场安装「通览·跳转奇安信浏览器」
- **Windows 另需**：已安装 [Python 3](https://www.python.org/downloads/)；在 **Python 官方安装向导**里勾选 **Add python.exe to PATH** / 将 Python 添加到环境变量（终端才能直接运行 `python`）。装完请关闭并重新打开 PowerShell

## macOS 一键安装

### 只用 Firefox

```bash
curl -fsSL https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.sh | bash
```

### 还要用 Chrome / Edge

```bash
curl -fsSL https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.sh | bash -s -- <Chrome扩展ID>
```

## Windows 一键安装

在 **PowerShell** 中执行（不要用 CMD）：

### 只用 Firefox

```powershell
irm https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.ps1 | iex
```

### 还要用 Chrome / Edge

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.ps1))) -ChromeExtensionId <Chrome扩展ID>
```

或先下载再执行：

```powershell
irm https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.ps1 -OutFile install-native-host.ps1
.\install-native-host.ps1 -ChromeExtensionId <Chrome扩展ID>
```

## 安装后检查

1. 点击扩展图标  
2. 点「重新检测 Native Host」  
3. 应显示：**Native Host 已连通（com.tonglan.qax_open）**

## 本仓库文件

| 文件 | 平台 | 作用 |
|------|------|------|
| `install-native-host.sh` | macOS | 注册 Native Messaging |
| `install-native-host.ps1` | Windows | 注册 Native Messaging（写注册表） |
| `open-qax.py` | 双端 | 打开 Qaxbrowser |
| `open-qax-host.bat` | Windows | 供浏览器调用的启动器（转调 Python） |
| `LICENSE` | - | MIT |

**不包含**扩展源码。

## 常见问题

**Q: Windows 提示 python_not_found？**  
A: 安装 Python 3，在 **Python 官方安装向导**里勾选 “Add python.exe to PATH”，关掉并重新打开 PowerShell 后再装一次。

**Q: Windows 提示 qaxbrowser_not_found？**  
A: 确认已安装奇安信浏览器；若安装路径特殊，把该 `exe` 所在文件夹加到系统环境变量 Path 后再试，或把实际路径反馈给维护者。

**Q: 换电脑要重装吗？**  
A: 要。每台电脑装一次即可。

## 许可

见 [LICENSE](./LICENSE)。

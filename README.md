# tonglan-qax-native-host

为浏览器扩展 **「通览·跳转奇安信浏览器」** 安装本机 **Native Host**（**macOS / Windows**）。

商店只能安装扩展本身，**不能**自动写入系统脚本。扩展要调用奇安信浏览器（Qaxbrowser），必须先在本机安装本仓库提供的 Native Host。

仓库地址：<https://github.com/yexinjia/tonglan-qax-native-host>

## 你需要什么

- **macOS** 或 **Windows（Win10 及以上，含更新版本）**
- 已安装奇安信浏览器（Qaxbrowser）
- 已从 Firefox / Chrome / Edge 插件市场安装「通览·跳转奇安信浏览器」
- **Windows 另需**：已安装 [Python 3](https://www.python.org/downloads/)；在 **Python 官方安装向导**里勾选 **Add python.exe to PATH** / 将 Python 添加到环境变量（终端才能直接运行 `python`）。装完请关闭并重新打开 PowerShell

## macOS 一键安装

### Firefox

```bash
curl -fsSL https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.sh | bash
```

### Chrome 或 Edge

在扩展弹窗复制扩展 ID，执行（只装你正在用的那一个即可）：

```bash
curl -fsSL https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.sh | bash -s -- <扩展ID>
```

本地已有仓库时：

```bash
./install-native-host.sh <扩展ID>
```

> 若还要用另一个浏览器，再对其扩展 ID 执行一次即可（会合并，不覆盖）。

## Windows 一键安装

在 **PowerShell** 中执行（不要用 CMD）：

### Firefox

```powershell
irm https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.ps1 | iex
```

### Chrome 或 Edge

在扩展弹窗复制扩展 ID，执行（只装你正在用的那一个即可）：

```powershell
irm https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.ps1 -OutFile install-native-host.ps1
.\install-native-host.ps1 -ChromeExtensionId <扩展ID>
```

> 若还要用另一个浏览器，再对其扩展 ID 执行一次即可（会合并，不覆盖）。

## 若 raw.githubusercontent.com 打不开

国内网络有时无法访问 `raw.githubusercontent.com`（一键 `curl` / `irm` 会失败）。可改用克隆仓库后本地安装：

```bash
git clone https://github.com/yexinjia/tonglan-qax-native-host.git
cd tonglan-qax-native-host
./install-native-host.sh                 # Firefox
./install-native-host.sh <扩展ID>        # Chrome 或 Edge
```

Windows（PowerShell）：

```powershell
git clone https://github.com/yexinjia/tonglan-qax-native-host.git
cd tonglan-qax-native-host
.\install-native-host.ps1
.\install-native-host.ps1 -ChromeExtensionId <扩展ID>
```

也可在 GitHub 页面下载 ZIP，解压后运行对应脚本。

## 安装后验证

1. 打开扩展弹窗 → **「重新检测 Native Host」** → 显示已连通  
2. 或在终端：`open -a Qaxbrowser 'https://git-biz.qianxin-inc.cn/'`（macOS）

自定义 Qaxbrowser 路径等高级选项见扩展弹窗说明。

## 许可

MIT

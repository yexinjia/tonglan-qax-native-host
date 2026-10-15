# tonglan-qax-native-host

为浏览器扩展 **「通览·跳转奇安信浏览器」** 安装本机 **Native Host**（**macOS / Windows**）。

商店只能安装扩展本身，**不能**自动写入系统脚本。扩展要调用奇安信浏览器（Qaxbrowser），必须先在本机安装本仓库提供的 Native Host。

仓库地址：<https://github.com/yexinjia/tonglan-qax-native-host>

## 最短上手（约 2 分钟）

1. 浏览器装好「通览·跳转奇安信浏览器」扩展
2. 本机已安装奇安信浏览器（Qaxbrowser）
3. 按下面对应系统执行 **一条** 安装命令（Firefox 可不带 ID；Chrome / Edge 要带扩展 ID）
4. 点扩展图标 →「重新检测 Native Host」→ 显示已连通
5. 打开一个匹配站点（如内网 git），应跳到奇安信浏览器

**扩展 ID 在哪看：** 打开 `chrome://extensions` 或 `edge://extensions`，开启「开发人员模式」，在本扩展卡片上复制 ID；扩展弹窗里也可复制。

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

## 自定义 Qaxbrowser 路径

若自动找不到浏览器（例如装在 D/E 盘），在扩展弹窗「Qaxbrowser 路径」中填入本机可执行文件完整路径并保存，例如：

`C:\Program Files\Qaxbrowser\Application\qaxbrowser.exe`

路径保存在本机 Native Host 配置中；留空并保存可恢复自动查找。

## 常见问题

**Q: Windows 提示 python_not_found？**
A: 安装 Python 3，在 **Python 官方安装向导**里勾选 “Add python.exe to PATH”，关掉并重新打开 PowerShell 后再装一次。

**Q: Windows 提示 qaxbrowser_not_found？**
A: 确认已安装奇安信浏览器。默认会找 `…\Qaxbrowser\Application\qaxbrowser.exe`（含 C 盘 Program Files）。若装在 D/E 盘且不在常见目录，把该 `exe` 所在文件夹加到 Path，或在扩展弹窗填写自定义路径。

**Q: 安装命令成功了，但弹窗仍显示未连通？**
A: 完全退出浏览器再打开（不要只关标签页）。确认安装命令用的是**当前这个浏览器**的扩展 ID。

**Q: 跳转时没反应或仍停在 Chrome/Edge？**
A: 先确认 Native Host 已连通；再确认地址在匹配站点列表内（弹窗可添加自定义规则）。本机需能单独启动 Qaxbrowser。

**Q: 换电脑要重装吗？**
A: 要。每台电脑装一次即可。

**Q: Chrome 能用但 Edge 不行（或反过来）？**
A: 两个浏览器扩展 ID 不同。对另一个浏览器的扩展 ID 再执行一次安装命令即可（会合并，不覆盖）。

## 许可

见 [LICENSE](./LICENSE)。

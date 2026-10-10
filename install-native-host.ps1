# Install Native Messaging host for 通览·跳转奇安信浏览器 (Windows)
# Requires: Python 3 on PATH (py / python / python3), Qaxbrowser installed
# Usage:
#   irm https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.ps1 | iex
#   OR: .\install-native-host.ps1
#   Chrome/Edge: .\install-native-host.ps1 -ChromeExtensionId <id>
param(
  [string]$ChromeExtensionId = $env:EXTENSION_ID
)

$ErrorActionPreference = "Stop"
$HostName = "com.tonglan.qax_open"
$GeckoId = "tonglan-qax-open@local"
$RawBase = "https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main"
$SupportDir = Join-Path $env:LOCALAPPDATA "tonglan-qax-open"
$IdFile = Join-Path $SupportDir "chrome-extension-id.txt"

New-Item -ItemType Directory -Force -Path $SupportDir | Out-Null

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

function Get-PythonCmd {
  foreach ($c in @("py", "python", "python3")) {
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if ($cmd) { return $c }
  }
  return $null
}

if (-not (Get-PythonCmd)) {
  Write-Error "未找到 Python 3。请先安装 https://www.python.org/downloads/ ，安装界面勾选 Add python.exe to PATH，完成后重新打开 PowerShell 再试。"
}

$files = @("open-qax.py", "open-qax-host.bat")
foreach ($f in $files) {
  $local = Join-Path $ScriptDir $f
  $dest = Join-Path $SupportDir $f
  if (Test-Path $local) {
    Copy-Item -Force $local $dest
  } else {
    Write-Host "正在下载 $f ..."
    Invoke-WebRequest -UseBasicParsing -Uri "$RawBase/$f" -OutFile $dest
  }
}

$HostBat = Join-Path $SupportDir "open-qax-host.bat"
# Native Messaging JSON uses escaped backslashes
$HostBatJson = $HostBat.Replace("\", "\\")

function Write-NmManifest([string]$Path, [hashtable]$Extra) {
  $dir = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $obj = [ordered]@{
    name = $HostName
    description = "Open URL in Qaxbrowser for Tonglan Qax Open"
    path = $HostBat
    type = "stdio"
  }
  foreach ($k in $Extra.Keys) { $obj[$k] = $Extra[$k] }
  ($obj | ConvertTo-Json -Compress:$false) + "`n" | Set-Content -Encoding UTF8 -Path $Path
  Write-Host "已写入: $Path"
}

function Set-NmRegistry([string]$BrowserKey, [string]$ManifestPath) {
  $key = "HKCU:\Software\$BrowserKey\NativeMessagingHosts\$HostName"
  New-Item -Path $key -Force | Out-Null
  Set-ItemProperty -Path $key -Name "(default)" -Value $ManifestPath
  Write-Host "已注册: $key"
}

# Firefox
$ffManifest = Join-Path $SupportDir "$HostName.firefox.json"
Write-NmManifest $ffManifest @{ allowed_extensions = @($GeckoId) }
Set-NmRegistry "Mozilla" $ffManifest

# Chrome / Chromium / Edge if ID provided
if (-not $ChromeExtensionId -and (Test-Path $IdFile)) {
  $ChromeExtensionId = (Get-Content $IdFile -Raw).Trim()
}

if ($ChromeExtensionId) {
  $origin = "chrome-extension://$ChromeExtensionId/"
  $chromeManifest = Join-Path $SupportDir "$HostName.chrome.json"
  Write-NmManifest $chromeManifest @{ allowed_origins = @($origin) }
  Set-NmRegistry "Google\Chrome" $chromeManifest
  Set-NmRegistry "Chromium" $chromeManifest
  Set-NmRegistry "Microsoft\Edge" $chromeManifest
  Set-Content -Path $IdFile -Value $ChromeExtensionId -Encoding UTF8
  Write-Host "Chrome origin: $origin"
} else {
  Write-Host ""
  Write-Host "已安装 Firefox Native Host（无需扩展 ID）。"
  Write-Host "若还要在 Chrome / Edge 使用:"
  Write-Host "  .\install-native-host.ps1 -ChromeExtensionId <扩展ID>"
  Write-Host "或:"
  Write-Host "  irm $RawBase/install-native-host.ps1 | iex"
  Write-Host "（先设置 `$env:EXTENSION_ID='你的ID'）"
}

Write-Host ""
Write-Host "Host: $HostBat"
Write-Host "安装完成。请在扩展弹窗点「重新检测 Native Host」。"
Write-Host "说明: https://github.com/yexinjia/tonglan-qax-native-host"

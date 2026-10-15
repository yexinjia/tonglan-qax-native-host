# Install Native Messaging host for 通览·跳转奇安信浏览器 (Windows)
# Requires: Python 3 on PATH (py / python / python3), Qaxbrowser installed
# Usage:
#   irm https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.ps1 | iex
#   OR: .\install-native-host.ps1
#   Chrome/Edge: .\install-native-host.ps1 -ChromeExtensionId id1,id2
param(
  [string[]]$ChromeExtensionId = @()
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

function Split-ExtensionIds([string[]]$Raw) {
  $out = [System.Collections.Generic.List[string]]::new()
  foreach ($item in $Raw) {
    if (-not $item) { continue }
    foreach ($part in ($item -split '[,\s]+')) {
      $p = $part.Trim()
      if ($p) { $out.Add($p) }
    }
  }
  return $out
}

function Read-IdsFromFile([string]$Path) {
  if (-not (Test-Path $Path)) { return @() }
  $text = (Get-Content $Path -Raw -ErrorAction SilentlyContinue)
  if (-not $text) { return @() }
  $text = $text.Trim()
  if (-not $text) { return @() }
  if ($text.StartsWith("[")) {
    $parsed = $text | ConvertFrom-Json
    if ($parsed -is [string]) { return @($parsed.Trim()) }
    return @($parsed | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
  }
  $ids = [System.Collections.Generic.List[string]]::new()
  foreach ($line in ($text -split "`n")) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith("#")) { continue }
    foreach ($part in ($line -split '[,\s]+')) {
      $p = $part.Trim()
      if ($p) { $ids.Add($p) }
    }
  }
  if ($ids.Count -eq 0) { return @($text.Trim()) }
  return @($ids)
}

function Merge-ExtensionIds([string[]]$Existing, [string[]]$New) {
  $seen = @{}
  $merged = [System.Collections.Generic.List[string]]::new()
  foreach ($id in ($Existing + $New)) {
    if (-not $id) { continue }
    if (-not $seen.ContainsKey($id)) {
      $seen[$id] = $true
      $merged.Add($id)
    }
  }
  return @($merged)
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

$newIds = Split-ExtensionIds $ChromeExtensionId
if ($newIds.Count -eq 0 -and $env:EXTENSION_ID) {
  $newIds = Split-ExtensionIds @($env:EXTENSION_ID)
}

$existingIds = Read-IdsFromFile $IdFile
$allIds = Merge-ExtensionIds $existingIds $newIds

if ($allIds.Count -gt 0) {
  foreach ($id in $allIds) {
    if ($id -notmatch '^[a-p]{32}$') {
      Write-Warning "扩展 ID「$id」看起来不像 Chrome 扩展 ID（通常是 32 位 a-p）。继续安装…"
    }
  }
  $origins = @($allIds | ForEach-Object { "chrome-extension://$_/" })
  $chromeManifest = Join-Path $SupportDir "$HostName.chrome.json"
  Write-NmManifest $chromeManifest @{ allowed_origins = $origins }
  Set-NmRegistry "Google\Chrome" $chromeManifest
  Set-NmRegistry "Chromium" $chromeManifest
  Set-NmRegistry "Microsoft\Edge" $chromeManifest
  ($allIds -join "`n") + "`n" | Set-Content -Path $IdFile -Encoding UTF8 -NoNewline:$false
  Write-Host "Chrome origins:"
  foreach ($o in $origins) { Write-Host "  $o" }
} else {
  Write-Host ""
  Write-Host "已安装 Firefox Native Host（无需扩展 ID）。"
  Write-Host "若还要在 Chrome / Edge 使用:"
  Write-Host "  .\install-native-host.ps1 -ChromeExtensionId <扩展ID>[,<第二个ID>…]"
  Write-Host "或:"
  Write-Host "  irm $RawBase/install-native-host.ps1 | iex"
  Write-Host "（先设置 `$env:EXTENSION_ID='你的ID'；再次安装会合并 ID，不会覆盖）"
}

Write-Host ""
Write-Host "Host: $HostBat"
Write-Host "安装完成。请在扩展弹窗点「重新检测 Native Host」。"
Write-Host "说明: https://github.com/yexinjia/tonglan-qax-native-host"

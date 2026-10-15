#!/usr/bin/env bash
# Install Native Messaging host for 通览·跳转奇安信浏览器 (macOS)
# Windows users: use install-native-host.ps1 instead
# Repo: https://github.com/yexinjia/tonglan-qax-native-host
set -euo pipefail

HOST_NAME="com.tonglan.qax_open"
GECKO_ID="tonglan-qax-open@local"
RAW_BASE="https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main"
SUPPORT_DIR="${HOME}/Library/Application Support/tonglan-qax-open"
HOST_DST="${SUPPORT_DIR}/open-qax.py"
ID_FILE="${HOME}/Library/Application Support/tonglan-qax-open/chrome-extension-id"

CHROME_NM="${HOME}/Library/Application Support/Google/Chrome/NativeMessagingHosts"
CHROMIUM_NM="${HOME}/Library/Application Support/Chromium/NativeMessagingHosts"
EDGE_NM="${HOME}/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
FIREFOX_NM="${HOME}/Library/Application Support/Mozilla/NativeMessagingHosts"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_HOST="${SCRIPT_DIR}/open-qax.py"

# Collect new IDs from CLI args (space- or comma-separated) and/or EXTENSION_ID
NEW_IDS=()
if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    arg="${arg//,/ }"
    for part in $arg; do
      part="${part//[[:space:]]/}"
      [[ -n "${part}" ]] && NEW_IDS+=("${part}")
    done
  done
elif [[ -n "${EXTENSION_ID:-}" ]]; then
  ext="${EXTENSION_ID//,/ }"
  for part in $ext; do
    part="${part//[[:space:]]/}"
    [[ -n "${part}" ]] && NEW_IDS+=("${part}")
  done
fi

merge_ids() {
  python3 - "${ID_FILE}" "${NEW_IDS[@]}" <<'PY'
import json, sys
from pathlib import Path

def load_ids(path):
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        return []
    ids = []
    if text.startswith("["):
        raw = json.loads(text)
        if isinstance(raw, str):
            ids = [raw]
        else:
            ids = [str(x).strip() for x in raw if str(x).strip()]
    else:
        for line in text.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            for part in line.replace(",", " ").split():
                part = part.strip()
                if part:
                    ids.append(part)
        if not ids:
            ids = [text.strip()]
    return ids

file_path = Path(sys.argv[1])
new_ids = [x.strip() for x in sys.argv[2:] if x.strip()]
merged = []
seen = set()
for i in load_ids(file_path) + new_ids:
    if i not in seen:
        seen.add(i)
        merged.append(i)
for i in merged:
    print(i)
PY
}

mkdir -p "${SUPPORT_DIR}"

if [[ -f "${LOCAL_HOST}" ]]; then
  cp "${LOCAL_HOST}" "${HOST_DST}"
else
  echo "正在下载 open-qax.py …"
  curl -fsSL "${RAW_BASE}/open-qax.py" -o "${HOST_DST}"
fi
chmod +x "${HOST_DST}"

write_chrome_manifest() {
  local nm_dir="$1"
  shift
  mkdir -p "${nm_dir}"
  python3 - "$nm_dir" "$HOST_NAME" "$HOST_DST" "$@" <<'PY'
import json, sys
from pathlib import Path

nm_dir, host_name, host_dst = sys.argv[1:4]
origins = sys.argv[4:]
manifest = {
    "name": host_name,
    "description": "Open URL in Qaxbrowser for Tonglan Qax Open",
    "path": host_dst,
    "type": "stdio",
    "allowed_origins": origins,
}
path = Path(nm_dir) / f"{host_name}.json"
path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"已写入 Chromium 系: {path}")
for origin in origins:
    print(f"  Origin: {origin}")
PY
}

write_firefox_manifest() {
  mkdir -p "${FIREFOX_NM}"
  python3 - "$FIREFOX_NM" "$GECKO_ID" "$HOST_NAME" "$HOST_DST" <<'PY'
import json, sys
from pathlib import Path
nm_dir, gecko_id, host_name, host_dst = sys.argv[1:5]
manifest = {
    "name": host_name,
    "description": "Open URL in Qaxbrowser for Tonglan Qax Open",
    "path": host_dst,
    "type": "stdio",
    "allowed_extensions": [gecko_id],
}
path = Path(nm_dir) / f"{host_name}.json"
path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"已写入 Firefox: {path}")
print(f"  Extension: {gecko_id}")
PY
}

write_firefox_manifest

mapfile -t EXT_IDS < <(merge_ids)

if [[ ${#EXT_IDS[@]} -gt 0 ]]; then
  ORIGINS=()
  for id in "${EXT_IDS[@]}"; do
    if [[ ! "${id}" =~ ^[a-p]{32}$ ]]; then
      echo "警告: 扩展 ID「${id}」看起来不像 Chrome 扩展 ID（通常是 32 位 a-p）。继续安装…" >&2
    fi
    ORIGINS+=("chrome-extension://${id}/")
  done
  write_chrome_manifest "${CHROME_NM}" "${ORIGINS[@]}"
  write_chrome_manifest "${CHROMIUM_NM}" "${ORIGINS[@]}"
  write_chrome_manifest "${EDGE_NM}" "${ORIGINS[@]}"
  printf '%s\n' "${EXT_IDS[@]}" > "${ID_FILE}"
  echo ""
  if [[ ${#EXT_IDS[@]} -eq 1 ]]; then
    echo "已登记扩展 ID: ${EXT_IDS[0]}"
  else
    echo "已登记扩展 ID（共 ${#EXT_IDS[@]} 个）："
    for id in "${EXT_IDS[@]}"; do
      echo "  - ${id}"
    done
  fi
else
  echo ""
  echo "已安装 Firefox Native Host（无需扩展 ID）。"
  echo "若还要在 Chrome / Edge 使用，请再执行:"
  echo "  curl -fsSL https://raw.githubusercontent.com/yexinjia/tonglan-qax-native-host/main/install-native-host.sh | bash -s -- <Chrome扩展ID>"
  echo "（扩展 ID 在 chrome://extensions 打开开发者模式后复制）"
fi

echo ""
echo "Host 脚本: ${HOST_DST}"
echo "安装完成。请回到浏览器，打开扩展弹窗 →「重新检测 Native Host」。"
echo "验证: open -a Qaxbrowser 'https://git-biz.qianxin-inc.cn/'"
echo "说明: https://github.com/yexinjia/tonglan-qax-native-host"

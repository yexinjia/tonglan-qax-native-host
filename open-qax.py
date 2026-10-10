#!/usr/bin/env python3
"""Native Messaging host: open URL in Qaxbrowser (macOS / Windows)."""
import json
import os
import shutil
import struct
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse

ALLOWED_SCHEMES = {"http", "https"}


def read_message():
    raw_length = sys.stdin.buffer.read(4)
    if len(raw_length) == 0:
        return None
    if len(raw_length) < 4:
        sys.exit(1)
    length = struct.unpack("<I", raw_length)[0]
    if length <= 0 or length > 1024 * 1024:
        sys.exit(1)
    data = sys.stdin.buffer.read(length)
    return json.loads(data.decode("utf-8"))


def send_message(msg):
    encoded = json.dumps(msg, ensure_ascii=False).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("<I", len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()


def is_safe_url(url):
    try:
        parsed = urlparse(url)
    except Exception:
        return False
    if parsed.scheme not in ALLOWED_SCHEMES:
        return False
    if not parsed.netloc:
        return False
    return True


def find_qaxbrowser_windows():
    env = os.environ
    names = [
        "Qaxbrowser.exe",
        "QaxBrowser.exe",
        "奇安信可信浏览器.exe",
        "奇安信浏览器.exe",
    ]
    roots = []
    for key in ("PROGRAMFILES", "PROGRAMFILES(X86)", "LOCALAPPDATA", "PROGRAMW6432"):
        val = env.get(key) or env.get(key.title())
        if val:
            roots.append(Path(val))
    # Common vendor folders
    extra = []
    for root in list(roots):
        for child in ("Qaxbrowser", "QAXBrowser", "QiAnXin", "qianxin", "奇安信", "奇安信可信浏览器"):
            extra.append(root / child)
    roots.extend(extra)

    for root in roots:
        for name in names:
            candidate = root / name
            if candidate.is_file():
                return str(candidate)
            # one level deeper
            try:
                for path in root.glob("*/" + name):
                    if path.is_file():
                        return str(path)
            except OSError:
                pass

    # PATH lookup
    for name in names:
        found = shutil.which(name)
        if found:
            return found
    return None


def open_in_qaxbrowser(url):
    if sys.platform == "darwin":
        result = subprocess.run(
            ["open", "-a", "Qaxbrowser", url],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            err = (result.stderr or result.stdout or "open_failed").strip()
            return False, err or "open_failed"
        return True, None

    if sys.platform.startswith("win"):
        exe = find_qaxbrowser_windows()
        if not exe:
            return False, "qaxbrowser_not_found"
        # Avoid console window flash where possible
        creationflags = 0
        if hasattr(subprocess, "CREATE_NO_WINDOW"):
            creationflags = subprocess.CREATE_NO_WINDOW
        result = subprocess.run(
            [exe, url],
            capture_output=True,
            text=True,
            timeout=30,
            creationflags=creationflags,
        )
        if result.returncode != 0:
            err = (result.stderr or result.stdout or "open_failed").strip()
            return False, err or "open_failed"
        return True, None

    return False, f"unsupported_platform:{sys.platform}"


def main():
    msg = read_message()
    if msg is None:
        return

    if msg.get("ping"):
        send_message({"ok": True, "pong": True, "platform": sys.platform})
        return

    url = (msg.get("url") or "").strip()
    if not is_safe_url(url):
        send_message({"ok": False, "error": "invalid_url"})
        return
    try:
        ok, err = open_in_qaxbrowser(url)
        if ok:
            send_message({"ok": True, "url": url})
        else:
            send_message({"ok": False, "error": err or "open_failed"})
    except Exception as exc:
        send_message({"ok": False, "error": str(exc)})


if __name__ == "__main__":
    main()

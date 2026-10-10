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
MAX_PATH_LEN = 1024


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


def support_dir():
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/tonglan-qax-open"
    if sys.platform.startswith("win"):
        base = os.environ.get("LOCALAPPDATA") or str(Path.home() / "AppData/Local")
        return Path(base) / "tonglan-qax-open"
    return Path.home() / ".tonglan-qax-open"


def config_file():
    return support_dir() / "config.json"


def load_config():
    path = config_file()
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def save_config(data):
    d = support_dir()
    d.mkdir(parents=True, exist_ok=True)
    config_file().write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def normalize_browser_path(raw):
    text = str(raw or "").strip().strip('"').strip("'")
    if not text:
        return ""
    if len(text) > MAX_PATH_LEN:
        raise ValueError("path_too_long")
    if "\x00" in text:
        raise ValueError("invalid_path")
    p = Path(text).expanduser()
    if not p.is_absolute():
        raise ValueError("path_not_absolute")
    return str(p)


def path_looks_usable(path_str):
    if not path_str:
        return False
    p = Path(path_str)
    if sys.platform == "darwin" and p.suffix.lower() == ".app":
        return p.is_dir()
    return p.is_file()


def find_qaxbrowser_windows():
    """Locate Qaxbrowser on Windows.

    Real install (colleague sample):
      C:\\Program Files\\Qaxbrowser\\Application\\qaxbrowser.exe
    """
    env = os.environ
    names = [
        "qaxbrowser.exe",
        "Qaxbrowser.exe",
        "QaxBrowser.exe",
        "奇安信可信浏览器.exe",
        "奇安信浏览器.exe",
    ]
    relative_candidates = [
        Path("Qaxbrowser") / "Application" / "qaxbrowser.exe",
        Path("Qaxbrowser") / "Application" / "Qaxbrowser.exe",
        Path("Qaxbrowser") / "qaxbrowser.exe",
        Path("Qaxbrowser") / "Qaxbrowser.exe",
    ]

    roots = []
    for key in ("PROGRAMFILES", "PROGRAMFILES(X86)", "LOCALAPPDATA", "PROGRAMW6432"):
        val = env.get(key) or env.get(key.title())
        if val:
            roots.append(Path(val))

    for root in roots:
        for rel in relative_candidates:
            candidate = root / rel
            if candidate.is_file():
                return str(candidate)

    for root in roots:
        base = root / "Qaxbrowser"
        if not base.is_dir():
            continue
        try:
            for name in names:
                for path in base.rglob(name):
                    if path.is_file():
                        return str(path)
        except OSError:
            pass

    for name in names:
        found = shutil.which(name)
        if found:
            return found
    return None


def launch_with_path(exe_or_app, url):
    if sys.platform == "darwin":
        p = Path(exe_or_app)
        if p.suffix.lower() == ".app" or (p.is_dir() and p.suffix.lower() == ".app"):
            result = subprocess.run(
                ["open", "-a", str(p), url],
                capture_output=True,
                text=True,
                timeout=30,
            )
        else:
            result = subprocess.run(
                [str(p), url],
                capture_output=True,
                text=True,
                timeout=30,
            )
        if result.returncode != 0:
            err = (result.stderr or result.stdout or "open_failed").strip()
            return False, err or "open_failed"
        return True, None

    if sys.platform.startswith("win"):
        creationflags = 0
        if hasattr(subprocess, "CREATE_NO_WINDOW"):
            creationflags = subprocess.CREATE_NO_WINDOW
        result = subprocess.run(
            [exe_or_app, url],
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


def open_in_qaxbrowser(url):
    cfg = load_config()
    custom = str(cfg.get("qaxbrowserPath") or "").strip()
    if custom:
        if not path_looks_usable(custom):
            return False, "custom_path_invalid"
        return launch_with_path(custom, url)

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
        return launch_with_path(exe, url)

    return False, f"unsupported_platform:{sys.platform}"


def handle_get_config():
    cfg = load_config()
    path = str(cfg.get("qaxbrowserPath") or "")
    return {
        "ok": True,
        "qaxbrowserPath": path,
        "customPathValid": path_looks_usable(path) if path else None,
        "platform": sys.platform,
    }


def handle_set_config(msg):
    raw = msg.get("qaxbrowserPath", "")
    try:
        normalized = normalize_browser_path(raw)
    except ValueError as exc:
        return {"ok": False, "error": str(exc)}

    cfg = load_config()
    if not normalized:
        cfg.pop("qaxbrowserPath", None)
        save_config(cfg)
        return {"ok": True, "qaxbrowserPath": "", "cleared": True}

    if not path_looks_usable(normalized):
        return {"ok": False, "error": "path_not_found"}

    cfg["qaxbrowserPath"] = normalized
    save_config(cfg)
    return {"ok": True, "qaxbrowserPath": normalized}


def main():
    msg = read_message()
    if msg is None:
        return

    if msg.get("ping"):
        cfg = load_config()
        send_message(
            {
                "ok": True,
                "pong": True,
                "platform": sys.platform,
                "qaxbrowserPath": str(cfg.get("qaxbrowserPath") or ""),
            }
        )
        return

    if msg.get("getConfig"):
        send_message(handle_get_config())
        return

    if msg.get("setConfig"):
        send_message(handle_set_config(msg))
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

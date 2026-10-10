@echo off
REM Native Messaging launcher for Windows (calls Python)
setlocal
set "SCRIPT_DIR=%~dp0"
where py >nul 2>nul
if %ERRORLEVEL%==0 (
  py -3 "%SCRIPT_DIR%open-qax.py" %*
  exit /b %ERRORLEVEL%
)
where python >nul 2>nul
if %ERRORLEVEL%==0 (
  python "%SCRIPT_DIR%open-qax.py" %*
  exit /b %ERRORLEVEL%
)
where python3 >nul 2>nul
if %ERRORLEVEL%==0 (
  python3 "%SCRIPT_DIR%open-qax.py" %*
  exit /b %ERRORLEVEL%
)
echo {"ok": false, "error": "python_not_found"} 1>&2
exit /b 1


@echo off
title TIPNav USB Testing

echo ==================================
echo       TIPNAV LOCAL TESTING
echo ==================================
echo.

:: Configuration
set "PORT=8000"
set "ADB=C:\platform-tools\adb.exe"

:: Check Python
echo Checking Python...
where python >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python was not found.
    pause
    exit /b 1
)

:: Check ADB
echo Checking ADB...
if not exist "%ADB%" (
    echo ERROR: ADB was not found at:
    echo %ADB%
    pause
    exit /b 1
)

echo ADB found!
echo.

:: Start HTTP server
echo Starting Python HTTP server...
start "TIPNav HTTP Server" cmd /k "cd /d ""%~dp0"" && python -m http.server %PORT%"

:: Wait for server initialization
timeout /t 2 /nobreak >nul

:: Check connected devices
echo.
echo Checking connected devices...
"%ADB%" devices

:: Configure USB reverse
echo.
echo Configuring USB forwarding...
"%ADB%" reverse tcp:%PORT% tcp:%PORT%

if errorlevel 1 (
    echo.
    echo ERROR: Could not configure USB forwarding.
    pause
    exit /b 1
)

:: Success
echo.
echo ==================================
echo         TIPNAV IS READY!
echo ==================================
echo.
echo Server: http://localhost:%PORT%
echo Phone:  http://localhost:%PORT%
echo.
echo Keep the HTTP Server window open.
echo.
pause

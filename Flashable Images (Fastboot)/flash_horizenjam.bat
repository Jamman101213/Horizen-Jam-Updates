@echo off
setlocal
echo ============================================================
echo   Horizen Jam 1.0 (Build HJ-0001) - Meta Quest 1 (monterey)
echo   Base: v50 (49845030443200410) ^| Donor UI: Quest 3 v2.10
echo ============================================================
echo.

if not exist "%~dp0boot.img" (
    echo [ERROR] boot.img not found in this folder!
    pause
    exit /b 1
)
if not exist "%~dp0system.img" (
    echo [ERROR] system.img not found in this folder!
    echo Please download system.img from the Horizen Jam GitHub Releases page
    echo and place it next to this script before running it.
    pause
    exit /b 1
)

echo [1/3] Flashing Magisk v31.1 patched boot.img (Safe 72 Hz default) to active slot...
fastboot flash boot "%~dp0boot.img" || goto :fail

echo.
echo [2/3] Flashing Horizen Jam 1.0 system.img to active slot...
fastboot flash system "%~dp0system.img" || goto :fail

echo.
echo [3/3] Rebooting into Horizen Jam 1.0...
fastboot reboot
echo.
echo Done! Future updates can be installed directly via Settings ^> Software Update.
pause
exit /b 0

:fail
echo.
echo [ERROR] Fastboot flashing failed! Make sure your Quest 1 has an unlocked
echo bootloader and is in fastboot mode (Hold Power + Volume Down).
pause
exit /b 1

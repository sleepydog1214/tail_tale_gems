@echo off
setlocal

:: This script opens the Godot Editor for this project so you can configure Android settings.
:: It uses the local Godot Mono executable.

set GODOT_EXE=godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64.exe

if not exist "%GODOT_EXE%" (
    echo Error: Godot executable not found at %GODOT_EXE%
    echo Please ensure the 'godot' folder is present or set GODOT_EXE environment variable.
    pause
    exit /b 1
)

echo Opening Godot Editor for project setup...
echo.
echo Once Godot opens, please perform these steps if needed:
echo 1. Project - Install Android Build Template
echo 2. Editor - Editor Settings - Export - Android - Java SDK Path
echo.

start "" "%GODOT_EXE%" --path . -e

endlocal

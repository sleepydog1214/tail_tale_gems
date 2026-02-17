@echo off
setlocal

set GODOT_GUI_EXE=godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64.exe

echo ============================================================
echo   Godot Android Export Helper (Editor GUI Mode)
echo ============================================================
echo.
echo Headless export sometimes fails due to missing Editor Settings
echo or uninitialized preset data. Running an export ONCE from the
echo Godot Editor UI often fixes these issues.
echo.
echo INSTRUCTIONS:
echo 1. The Godot Editor will now open.
echo 2. Go to: Project -^> Export...
echo 3. Select the "Android" preset.
echo 4. Check the "Options" tab on the right:
echo    - Ensure "Gradle Build" -^> "Use Gradle Build" is ENABLED (checked).
echo    - Ensure "Architectures" -^> "arm64-v8a" is ENABLED.
echo 5. Ensure "Editor" -^> "Editor Settings" -^> "Export" -^> "Android" has:
echo    - Android SDK Path (pointing to your Android SDK folder)
echo    - Java SDK Path (pointing to JDK 17 folder)
echo 6. Click "Export Project" at the bottom and save the APK once.
echo 7. Close Godot and re-run your 'android-deploy' command.
echo.
pause

if exist "%GODOT_GUI_EXE%" (
    echo Launching Godot Editor: %GODOT_GUI_EXE%
    start "" "%GODOT_GUI_EXE%" --path . -e
) else (
    echo ERROR: Godot GUI executable not found at: %GODOT_GUI_EXE%
    echo Please open the project in Godot manually.
    pause
)

endlocal

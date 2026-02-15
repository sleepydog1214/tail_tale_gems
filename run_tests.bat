@echo off
echo Running unit tests...
"%~dp0godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64_console.exe" --headless --path "%~dp0" res://tests/test_match_engine.tscn
echo.
echo Exit code: %ERRORLEVEL%
if %ERRORLEVEL% EQU 0 (
    echo ALL TESTS PASSED
) else (
    echo SOME TESTS FAILED
)
pause

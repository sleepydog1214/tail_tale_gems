@echo off
setlocal

:: Path to the PowerShell script
set PS_SCRIPT=scripts\android\deploy_android.ps1

:: Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo Error: %PS_SCRIPT% not found.
    exit /b 1
)

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

:: Capture exit code
set EXIT_CODE=%ERRORLEVEL%

if %EXIT_CODE% neq 0 (
    echo Android deploy failed with exit code %EXIT_CODE%
    exit /b %EXIT_CODE%
)

endlocal

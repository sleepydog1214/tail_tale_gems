$ApkPath = "build\android\TailTaleMatch-debug.apk"

if (-not (Test-Path $ApkPath)) {
    Write-Error "APK not found at $ApkPath. Run export_android_debug first."
    exit 1
}

# Check for adb
$DefaultSdkPath = "$env:LOCALAPPDATA\Android\Sdk"
if (-not (Get-Command "adb" -ErrorAction SilentlyContinue)) {
    if ($env:ANDROID_HOME -and (Test-Path "$env:ANDROID_HOME\platform-tools\adb.exe")) {
        $adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
    } elseif ($env:ANDROID_SDK_ROOT -and (Test-Path "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe")) {
        $adb = "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
    } elseif (Test-Path "$DefaultSdkPath\platform-tools\adb.exe") {
        $adb = "$DefaultSdkPath\platform-tools\adb.exe"
    } else {
        Write-Error "adb not found. Please install Android Platform Tools and add to PATH or set ANDROID_HOME."
        exit 1
    }
} else {
    $adb = "adb"
}

Write-Host "Installing APK to device..."
& $adb install -r $ApkPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "Install successful."
} else {
    Write-Error "Install failed."
    exit $LASTEXITCODE
}

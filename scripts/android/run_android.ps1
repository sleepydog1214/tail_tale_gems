$PackageName = "com.example.tailtalematch"
$MainActivity = "com.godot.game.GodotApp"

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

Write-Host "Launching $PackageName on device..."
& $adb shell am start -n "$PackageName/$MainActivity"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Launch command sent."
} else {
    Write-Error "Failed to launch app. Ensure it is installed and the package name is correct."
    Write-Host "Package Name: $PackageName"
    Write-Host "Main Activity: $MainActivity"
    exit $LASTEXITCODE
}

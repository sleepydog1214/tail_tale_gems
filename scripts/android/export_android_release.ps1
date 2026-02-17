$GodotPath = "godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64.exe"
$ExportPreset = "Android"
$OutputPath = "build\android\TailTaleMatch-release.apk"

if (-not (Test-Path $GodotPath)) {
    Write-Error "Godot executable not found at $GodotPath"
    exit 1
}

if (-not (Test-Path "export_presets.cfg")) {
    Write-Error "export_presets.cfg not found in project root."
    exit 1
}

if (-not (Test-Path "build\android")) {
    New-Item -ItemType Directory -Force -Path "build\android"
}

Write-Host "Exporting Android Release APK..."
& $GodotPath --headless --path . --export-release $ExportPreset $OutputPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "Export successful: $OutputPath"
} else {
    Write-Error "Export failed with exit code $LASTEXITCODE. Ensure release keystore is configured."
    exit $LASTEXITCODE
}

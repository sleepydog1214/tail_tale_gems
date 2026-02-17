# Android Pre-flight and Deploy Script

param (
    [switch]$SkipInstall,
    [switch]$PreflightOnly,
    [switch]$Verbose
)

$GodotRelativePath = "godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64.exe"
$GodotRelativePathConsole = "godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64_console.exe"
$ExportPreset = "Android"
$OutputPath = "build\android\TailTaleMatch-debug.apk"
$LogDir = "build\android\logs"
$ExportLogPath = Join-Path $LogDir "godot-export-android.log"
$ProjectRoot = Get-Location

Write-Host "=== Android Deployment Pre-flight Check ===" -ForegroundColor Cyan

# 1. Resolve Godot Executable
Write-Host "--- Resolving Godot ---"
$GodotExe = $null
$GodotGuiExe = $null

if ($env:GODOT_EXE -and (Test-Path $env:GODOT_EXE)) {
    $GodotExe = $env:GODOT_EXE
} elseif (Test-Path $GodotRelativePathConsole) {
    $GodotExe = Join-Path $ProjectRoot $GodotRelativePathConsole
    # Look for matching GUI exe
    if (Test-Path $GodotRelativePath) {
        $GodotGuiExe = Join-Path $ProjectRoot $GodotRelativePath
    }
} elseif (Test-Path $GodotRelativePath) {
    $GodotExe = Join-Path $ProjectRoot $GodotRelativePath
    $GodotGuiExe = $GodotExe
}

if (-not $GodotExe) {
    Write-Host "Error: Godot executable not found." -ForegroundColor Red
    Write-Host "Please set GODOT_EXE environment variable or ensure it exists in 'godot\' folder."
    exit 1
}

# For export, prefer GUI exe in headless mode to avoid console issues
$ExportGodotExe = if ($GodotGuiExe) { $GodotGuiExe } else { $GodotExe }

Write-Host "Using Godot (Console): $GodotExe"
if ($GodotGuiExe -and ($GodotGuiExe -ne $GodotExe)) {
    Write-Host "Using Godot (GUI):     $GodotGuiExe"
}
Write-Host "Using for export:    $ExportGodotExe"

# 2. Check Godot Version and Mono
Write-Host "--- Checking Godot Version ---"
$GodotVersionOutput = & $GodotExe --version --headless 2>&1
Write-Host "Godot Version: $GodotVersionOutput"
if ($GodotVersionOutput -notmatch "4\.6") {
    Write-Host "Warning: This project is designed for Godot 4.6. Detected version: $GodotVersionOutput" -ForegroundColor Yellow
}
if ($GodotVersionOutput -notmatch "mono") {
    Write-Host "Error: This project requires the Mono (C#) version of Godot." -ForegroundColor Red
    Write-Host "Please download the .NET / Mono version of Godot 4.6."
    exit 1
}

# 3. Check Android Export Templates
Write-Host "--- Checking Export Templates ---"

$RoamingTemplatesRoot = Join-Path $env:APPDATA "Godot\export_templates"
$LocalTemplatesRoot = Join-Path $env:LOCALAPPDATA "Godot\export_templates"
$SelfContainedTemplatesRoot = Join-Path (Split-Path $GodotExe) "editor_data\export_templates"

$SearchRoots = @()

# Priority 1: Environment variable overrides
if ($env:GODOT_TEMPLATES_DIR) {
    $SearchRoots += $env:GODOT_TEMPLATES_DIR
}
if ($env:GODOT_DATA_DIR) {
    $SearchRoots += Join-Path $env:GODOT_DATA_DIR "export_templates"
}

# Standard locations
$SearchRoots += @($RoamingTemplatesRoot, $LocalTemplatesRoot, $SelfContainedTemplatesRoot)

$TemplatesDir = $null
$Ver = $GodotVersionOutput.Trim()

# Detection Algorithm
foreach ($Root in $SearchRoots) {
    if (-not (Test-Path $Root)) { continue }
    
    # If root itself contains android_source.zip (user pointed directly to it)
    if (Test-Path (Join-Path $Root "android_source.zip")) {
        $TemplatesDir = $Root
        break
    }

    $Candidates = @()
    
    # Try exact match first
    if (Test-Path (Join-Path $Root $Ver)) {
        $Candidates += Join-Path $Root $Ver
    }
    
    # Try version prefixes
    $Parts = $Ver -split '\.'
    for ($i = $Parts.Count; $i -ge 1; $i--) {
        $Prefix = ($Parts[0..($i-1)] -join '.')
        if (Test-Path (Join-Path $Root $Prefix)) {
            $Candidates += Join-Path $Root $Prefix
        }
    }

    # Wildcard search for 4.6.*mono* (case-insensitive)
    try {
        $FoundDirs = Get-ChildItem -Path $Root -Directory -Filter "4.6*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*mono*" }
        foreach ($d in $FoundDirs) {
            $Candidates += $d.FullName
        }
    } catch {}

    # Filter for those containing android_source.zip and pick best (longest match)
    $ValidDirs = $Candidates | Select-Object -Unique | Where-Object { Test-Path (Join-Path $_ "android_source.zip") }
    
    if ($ValidDirs) {
        $TemplatesDir = $ValidDirs | Sort-Object Length -Descending | Select-Object -First 1
        break
    }
}

if (-not $TemplatesDir) {
    Write-Host "Error: Android export templates not found for Godot version $Ver" -ForegroundColor Red
    
    Write-Host "`nSearched locations:"
    foreach ($Root in ($SearchRoots | Select-Object -Unique)) {
        $Status = if (Test-Path $Root) { "Found" } else { "Not Found" }
        Write-Host "  - $Root ($Status)"
    }
    
    $AnyFound = $false
    foreach ($Root in ($SearchRoots | Select-Object -Unique)) {
        if (Test-Path $Root) {
            $Existing = Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue
            if ($Existing) {
                $AnyFound = $true
                Write-Host "`nFolders found in $Root`:"
                foreach ($d in $Existing) {
                    $HasZip = if (Test-Path (Join-Path $d.FullName "android_source.zip")) { "(has android_source.zip)" } else { "(MISSING android_source.zip)" }
                    Write-Host "  - $($d.Name) $HasZip"
                }
            }
        }
    }
    
    if (-not $AnyFound) {
        Write-Host "`nNo template folders found in any of the existing search locations."
    }

    Write-Host "`nTo fix this:"
    Write-Host "1. Open Godot Editor (non-console exe)."
    Write-Host "2. Go to Editor > Manage Export Templates."
    Write-Host "3. Ensure templates for 4.6.stable.mono are installed."
    Write-Host "   (If it says 'missing', click Download and Install)."
    Write-Host "   IMPORTANT: You MUST install the '.NET' or 'Mono' templates for this project."
    
    Write-Host "`nAlternatively, download manually:"
    Write-Host "1. Go to: https://godotengine.org/download/archive/4.6-stable/"
    Write-Host "2. Download 'Godot_v4.6-stable_mono_export_templates.tpz'."
    Write-Host "3. In Godot Editor: Manage Export Templates > Install From File."
    exit 1
}

Write-Host "Using Templates Dir: $TemplatesDir"
Write-Host "Templates found: OK"

# 4. Check Android Build Template (Project-specific)
Write-Host "--- Checking Android Build Template ---"
if (-not (Test-Path "android\build")) {
    Write-Host "Error: Android build template not installed in the project." -ForegroundColor Red
    Write-Host "`nTo fix this:"
    Write-Host "1. Open this project in Godot Editor."
    Write-Host "2. Go to Project > Install Android Build Template."
    Write-Host "3. Confirm the dialog to create the 'android/' directory."
    exit 1
}
if (-not (Test-Path "android\build\gradlew.bat")) {
    Write-Host "Error: 'android\build\gradlew.bat' not found. The Android build template seems incomplete." -ForegroundColor Red
    Write-Host "Try deleting the 'android/' folder and running 'Project > Install Android Build Template' again."
    exit 1
}
Write-Host "Build template found: OK"

# 5. Check Java SDK
Write-Host "--- Checking Java SDK ---"
$JavaPath = $null
if ($env:JAVA_HOME) {
    $JavaPath = Join-Path $env:JAVA_HOME "bin\java.exe"
}

# Try to find Godot's editor settings for Java path
$EditorSettingsPath = Join-Path $env:APPDATA "Godot\editor_settings-4.6.tres"
if (-not (Test-Path $EditorSettingsPath)) {
    # Fallback to any editor_settings-4*.tres
    $FallbackSettings = Get-ChildItem -Path "$env:APPDATA\Godot" -Filter "editor_settings-4*.tres" | Select-Object -First 1
    if ($FallbackSettings) { $EditorSettingsPath = $FallbackSettings.FullName }
}

$GodotJavaPath = $null
$GodotAndroidSdkPath = $null
if (Test-Path $EditorSettingsPath) {
    $SettingsContent = Get-Content $EditorSettingsPath -Raw
    if ($SettingsContent -match 'export/android/java_sdk_path\s*=\s*"([^"]+)"') {
        $GodotJavaPath = $Matches[1]
    }
    if ($SettingsContent -match 'export/android/android_sdk_path\s*=\s*"([^"]+)"') {
        $GodotAndroidSdkPath = $Matches[1]
    }
}

if (-not $env:JAVA_HOME -and -not $GodotJavaPath) {
    Write-Host "Error: Java SDK path not found in JAVA_HOME or Godot Editor Settings." -ForegroundColor Red
    Write-Host "`nTo fix this:"
    Write-Host "1. Install JDK 17 (recommended for Godot 4.6)."
    Write-Host "2. Set the path in Godot Editor:"
    Write-Host "   Editor > Editor Settings > Export > Android > Java SDK Path"
    Write-Host "   (Common path: C:/Program Files/Eclipse Adoptium/jdk-17.x.x.x-hotspot/)"
    exit 1
}

$FinalJavaPath = if ($GodotJavaPath) { $GodotJavaPath.Replace('/', '\') } else { $env:JAVA_HOME }
if (-not (Test-Path $FinalJavaPath)) {
    Write-Host "Error: Java SDK path does not exist: $FinalJavaPath" -ForegroundColor Red
    Write-Host "Please update your JAVA_HOME or Godot Editor Settings."
    exit 1
}
Write-Host "Java SDK: OK ($FinalJavaPath)" -ForegroundColor Gray

# 6. Resolve ADB
Write-Host "--- Resolving ADB ---"
$AdbExe = $null
$DefaultSdkPath = "$env:LOCALAPPDATA\Android\Sdk"

# Priority: Godot Editor Settings, then Environment, then local.properties, then default
$SearchSdkPaths = @()
if ($GodotAndroidSdkPath) { $SearchSdkPaths += $GodotAndroidSdkPath }
if ($env:ANDROID_HOME) { $SearchSdkPaths += $env:ANDROID_HOME }
if ($env:ANDROID_SDK_ROOT) { $SearchSdkPaths += $env:ANDROID_SDK_ROOT }

if (Test-Path "android\local.properties") {
    $SdkDir = Get-Content "android\local.properties" | Where-Object { $_ -match '^sdk\.dir\s*=' } | ForEach-Object {
        ($_ -split '=', 2)[1].Trim().Replace('\\', '\')
    }
    if ($SdkDir) { $SearchSdkPaths += $SdkDir }
}
$SearchSdkPaths += $DefaultSdkPath

foreach ($Path in $SearchSdkPaths) {
    if ($Path) {
        $CleanPath = $Path.Trim().Replace('/', '\').TrimEnd('\')
        if (Test-Path "$CleanPath\platform-tools\adb.exe") {
            $AdbExe = "$CleanPath\platform-tools\adb.exe"
            $ResolvedSdkPath = $CleanPath
            break
        }
    }
}

if (-not $AdbExe -and (Get-Command "adb" -ErrorAction SilentlyContinue)) {
    $AdbExe = (Get-Command "adb").Source
}

if (-not $AdbExe) {
    Write-Host "Error: ADB not found." -ForegroundColor Red
    Write-Host "Please set ANDROID_HOME environment variable or define sdk.dir in 'android\local.properties'."
    Write-Host "Alternatively, install Android Platform Tools and add 'adb' to your PATH."
    exit 1
}

# Verify SDK has platforms installed
if ($ResolvedSdkPath -and -not (Test-Path (Join-Path $ResolvedSdkPath "platforms"))) {
     Write-Host "Warning: Android SDK folder found, but 'platforms' directory is missing." -ForegroundColor Yellow
     Write-Host "Location: $ResolvedSdkPath"
     Write-Host "Please use SDK Manager to install at least one Android Platform (e.g., API 34)."
}

Write-Host "Using ADB: $AdbExe"
Write-Host "Android SDK: OK ($ResolvedSdkPath)" -ForegroundColor Gray

# 7. Verify Export Preset
Write-Host "--- Checking Export Preset ---"
if (-not (Test-Path "export_presets.cfg")) {
    Write-Host "Error: export_presets.cfg not found in project root." -ForegroundColor Red
    exit 1
}
$PresetsContent = Get-Content "export_presets.cfg" -Raw
if ($PresetsContent -notmatch "name=`"$ExportPreset`"") {
    Write-Host "Error: Export preset '$ExportPreset' not found in export_presets.cfg." -ForegroundColor Red
    exit 1
}

# Try to find debug keystore in editor settings
$GodotDebugKeystore = $null
if (Test-Path $EditorSettingsPath) {
    if ($SettingsContent -match 'export/android/debug_keystore\s*=\s*"([^"]+)"') {
        $GodotDebugKeystore = $Matches[1].Replace('/', '\')
    }
}

# Deep validation of Android preset
Write-Host "Validating '$ExportPreset' configuration..."
$PresetSection = $null
$InOptions = $false
$AndroidOptions = @{}

$Lines = Get-Content "export_presets.cfg"
$CurrentPresetName = ""
$IsAndroidPreset = $false

foreach ($Line in $Lines) {
    if ($Line -match "^\[preset\.\d+\]") {
        $IsAndroidPreset = $false
        $InOptions = $false
    } elseif ($Line -match '^name="([^"]+)"') {
        if ($Matches[1] -eq $ExportPreset) {
            $IsAndroidPreset = $true
        }
    } elseif ($IsAndroidPreset -and $Line -match "^\[preset\.\d+\.options\]") {
        $InOptions = $true
    } elseif ($InOptions -and $Line -match '^([^=]+)=(.*)$') {
        $Key = $Matches[1].Trim()
        $Value = $Matches[2].Trim()
        $AndroidOptions[$Key] = $Value
    }
}

$FailedValidation = $false
function Assert-PresetOption($Key, $ExpectedValue, $FriendlyName) {
    if (-not $AndroidOptions.ContainsKey($Key)) {
        Write-Host "  [FAIL] Missing option: $Key ($FriendlyName)" -ForegroundColor Red
        return $true
    }
    $ActualValue = $AndroidOptions[$Key]
    if ($ExpectedValue -ne $null -and $ActualValue -ne $ExpectedValue) {
        Write-Host "  [FAIL] Incorrect value for $Key ($FriendlyName). Expected $ExpectedValue, got $ActualValue" -ForegroundColor Red
        return $true
    }
    if ($ActualValue -eq '""' -or $ActualValue -eq "") {
         Write-Host "  [FAIL] Empty value for $Key ($FriendlyName)" -ForegroundColor Red
         return $true
    }
    Write-Host "  [OK] $FriendlyName ($Key=$ActualValue)" -ForegroundColor Gray
    return $false
}

$FailedValidation = (Assert-PresetOption "gradle_build/use_gradle_build" "true" "Use Gradle Build") -or $FailedValidation
$FailedValidation = (Assert-PresetOption "package/unique_name" $null "Unique Package Name") -or $FailedValidation
$FailedValidation = (Assert-PresetOption "gradle_build/min_sdk" $null "Min SDK") -or $FailedValidation
$FailedValidation = (Assert-PresetOption "gradle_build/target_sdk" $null "Target SDK") -or $FailedValidation

$HasArch = $false
if ($AndroidOptions["architecture/arm64-v8a"] -eq "true") { $HasArch = $true }
if ($AndroidOptions["architecture/armeabi-v7a"] -eq "true") { $HasArch = $true }

if (-not $HasArch) {
    Write-Host "  [FAIL] No ARM architecture enabled (arm64-v8a or armeabi-v7a)" -ForegroundColor Red
    $FailedValidation = $true
} else {
    Write-Host "  [OK] Architecture enabled" -ForegroundColor Gray
}

if ($FailedValidation) {
    Write-Host "`nError: Export preset '$ExportPreset' has configuration errors." -ForegroundColor Red
    Write-Host "Please fix these in Godot Editor: Project > Export > $ExportPreset"
    exit 1
}

# Check keystore
$KeystorePath = $AndroidOptions["keystore/debug"]
if ($KeystorePath -eq '""' -or $KeystorePath -eq "") {
    if ($GodotDebugKeystore) {
        Write-Host "  [OK] Using global debug keystore: $GodotDebugKeystore" -ForegroundColor Gray
        if (-not (Test-Path $GodotDebugKeystore)) {
             Write-Host "  [WARN] Global debug keystore file not found at $GodotDebugKeystore" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] No debug keystore defined in preset or editor settings." -ForegroundColor Yellow
    }
} else {
    $CleanKeystore = $KeystorePath.Trim('"').Replace('/', '\')
    Write-Host "  [OK] Using preset debug keystore: $CleanKeystore" -ForegroundColor Gray
    if (-not (Test-Path $CleanKeystore)) {
         Write-Host "  [FAIL] Preset debug keystore file not found: $CleanKeystore" -ForegroundColor Red
         $FailedValidation = $true
    }
}

if ($FailedValidation) {
    Write-Host "`nError: Export preset '$ExportPreset' has critical errors." -ForegroundColor Red
    exit 1
}
Write-Host "Preset '$ExportPreset': OK"

# 8. C#/.NET Diagnostics
Write-Host "--- C#/.NET Diagnostics ---"
Write-Host "Checking .NET SDK..."
$DotnetInfo = & dotnet --info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: 'dotnet --info' failed. Ensure .NET SDK is installed." -ForegroundColor Yellow
} else {
    $DotnetListSdks = & dotnet --list-sdks 2>&1
    Write-Host "Installed SDKs:"
    $DotnetListSdks | ForEach-Object { Write-Host "  - $_" }
    
    if ($DotnetListSdks -notmatch "[89]\.\d+") {
        Write-Host "Warning: Godot 4.6 Mono Android export may require .NET 8 or 9 SDK. Please verify." -ForegroundColor Yellow
    }
}

Write-Host "Checking for Android C# markers..."
if (Test-Path "android/build/libs") {
    Write-Host "  - android/build/libs found: OK" -ForegroundColor Gray
}
if (Test-Path "android/build/src/mono") {
    Write-Host "  - android/build/src/mono found: OK" -ForegroundColor Gray
}

Write-Host "`nNote: C# Android export is experimental; you may need to open the project in Godot Editor and export once to initialize settings." -ForegroundColor Cyan

if ($PreflightOnly) {
    Write-Host "`nPre-flight check passed!" -ForegroundColor Green
    exit 0
}

# 9. Export APK
Write-Host "`n--- Exporting Android ($ExportPreset) ---" -ForegroundColor Cyan
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
}
if (-not (Test-Path "build\android")) {
    New-Item -ItemType Directory -Force -Path "build\android" | Out-Null
}

# Log Godot Help once for reference
if (-not (Test-Path "$LogDir\godot-help.txt")) {
    & $ExportGodotExe --help | Out-File -FilePath "$LogDir\godot-help.txt" -Encoding utf8
}

$ExportCommand = "`"$ExportGodotExe`" --headless --verbose --path `"$ProjectRoot`" --export-debug `"$ExportPreset`" `"$OutputPath`""
Write-Host "Export command: $ExportCommand"
"Export Command: $ExportCommand`n" | Out-File -FilePath $ExportLogPath -Encoding utf8

Write-Host "Running Godot export... (logging to $ExportLogPath)"

# Run via CMD to avoid PowerShell RemoteException and ensure proper quoting
$CmdLine = "cmd.exe /c `"$ExportCommand 2>&1`""
$ExportResult = Invoke-Expression $CmdLine | Tee-Object -Variable FullOutput

# Log full output
$FullOutput | Out-File -FilePath $ExportLogPath -Append -Encoding utf8

if ($Verbose) {
    $FullOutput | Write-Host
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nExport failed with exit code $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Full log saved to: $ExportLogPath" -ForegroundColor Gray
    
    $LogLines = $FullOutput
    $FirstErrorIndex = -1
    for ($i = 0; $i -lt $LogLines.Count; $i++) {
        if ($LogLines[$i] -match "ERROR:") {
            $FirstErrorIndex = $i
            break
        }
    }

    if ($FirstErrorIndex -ge 0) {
        Write-Host "`n--- Most relevant log lines (around FIRST ERROR) ---" -ForegroundColor Yellow
        $Start = [Math]::Max(0, $FirstErrorIndex - 10)
        $End = [Math]::Min($LogLines.Count - 1, $FirstErrorIndex + 40)
        for ($i = $Start; $i -le $End; $i++) {
            $Prefix = if ($i -eq $FirstErrorIndex) { ">> " } else { "   " }
            $Color = if ($i -eq $FirstErrorIndex) { "Red" } else { "Gray" }
            Write-Host "$Prefix$($LogLines[$i])" -ForegroundColor $Color
        }
    } else {
        Write-Host "`n--- Last 50 lines of log ---" -ForegroundColor Gray
        $FullOutput | Select-Object -Last 50 | Write-Host
    }

    # Print lines matching important keywords
    $Keywords = @("configuration", "Android", "Gradle", "JDK", "SDK", "template", "mono", "dotnet", "C#")
    $MatchedLines = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $LogLines.Count; $i++) {
        $line = $LogLines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        foreach ($kw in $Keywords) {
            if ($line -match [Regex]::Escape($kw)) {
                $matchObj = New-Object PSObject -Property @{
                    Index = $i
                    Text = $line
                }
                [void]$MatchedLines.Add($matchObj)
                break
            }
        }
    }
    if ($MatchedLines.Count -gt 0) {
        Write-Host "`n--- Lines matching Android/.NET keywords ---" -ForegroundColor Yellow
        foreach ($m in $MatchedLines) {
            Write-Host ("[{0,4}] {1}" -f $m.Index, $m.Text) -ForegroundColor Gray
        }
    } else {
        Write-Host "`n(No lines matched Android/.NET keywords)" -ForegroundColor Gray
    }
    
    Write-Host "`n=== REMEDIATION CHECKLIST ===" -ForegroundColor Yellow
    Write-Host "1. Godot Editor Settings: Editor > Editor Settings > Export > Android"
    Write-Host "   - Ensure 'Android SDK Path' and 'Java SDK Path' are correct."
    Write-Host "2. Android Preset: Project > Export > Android"
    Write-Host "   - Confirm 'Use Gradle Build' is ENABLED."
    Write-Host "   - Ensure 'Export Path' in preset matches: $OutputPath"
    Write-Host "3. .NET Support: Ensure Godot 4.6 Mono export templates are installed."
    Write-Host "   - C# Android export is experimental and requires compatible .NET SDK."
    
    $IsExperimentalOnly = $true
    $HasExperimentalBanner = $false
    foreach ($line in $FullOutput) {
        if ($line -match "Exporting to Android when using C#/.NET is experimental") {
            $HasExperimentalBanner = $true
            continue
        }
        if ($line -match "ERROR:") {
            $IsExperimentalOnly = $false
            # We already found the first error and keywords, so we can stop searching here if we want, 
            # but we need to know if OTHER errors exist.
        }
    }

    if ($IsExperimentalOnly -and $HasExperimentalBanner) {
        Write-Host "`nGodot did not report specific config errors in headless mode; likely missing export preset options saved in editor settings or missing Android/.NET requirements." -ForegroundColor Cyan
        Write-Host "NOTE: Headless export relies on 'Editor Settings' being correctly initialized." -ForegroundColor Cyan
        Write-Host "Try running: scripts\android\open_godot_and_export_instructions.bat" -ForegroundColor White
        Write-Host "Then click 'Export Project' once manually to ensure all internal paths are initialized." -ForegroundColor White
    }
    
    $LogText = $FullOutput -join "`n"
    if ($LogText -match "EditorSettings not instantiated yet") {
        Write-Host "Note: 'EditorSettings not instantiated' is a common headless warning and usually not the root cause." -ForegroundColor White
    }
    
    Write-Host "`nLikely root causes from log:" -ForegroundColor Cyan
    if ($LogText -match "No export template found") {
        Write-Host "- MISSING TEMPLATES: Ensure Godot 4.6 Mono templates are installed."
    }
    if ($LogText -match "Android build template not installed") {
        Write-Host "- MISSING BUILD TEMPLATE: Run Project > Install Android Build Template."
    }
    if ($LogText -match "valid Java SDK path is required") {
        Write-Host "- JAVA SDK MISSING: Check Editor Settings."
    }
    if ($LogText -match 'gradlew\.bat" build') {
        Write-Host "- GRADLE BUILD FAILED: Check the log for Java/Android SDK version mismatches."
    }
    if ($LogText -match "configuration" -or $LogText -match "Gradle" -or $LogText -match "JDK" -or $LogText -match "SDK") {
        Write-Host "- CONFIGURATION ISSUE: Check lines containing 'configuration', 'Android', 'Gradle', 'JDK', 'SDK', 'template'."
    }
    
    exit $LASTEXITCODE
}
Write-Host "Export successful: $OutputPath" -ForegroundColor Green

if ($SkipInstall) {
    Write-Host "`nWorkflow completed (Export only)." -ForegroundColor Green
    exit 0
}

# 9. Install APK
Write-Host "`n--- Installing to Device ---" -ForegroundColor Cyan
& $AdbExe install -r $OutputPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: ADB install failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Install successful!" -ForegroundColor Green

# 10. Optional: Launch App
Write-Host "`n--- Launching App ---" -ForegroundColor Cyan
# Try to extract package name from export_presets.cfg
$PackageName = $null
if ($PresetsContent -match 'package/unique_name="([^"]+)"') {
    $PackageName = $Matches[1]
}

if ($PackageName) {
    $MainActivity = "com.godot.game.GodotApp"
    Write-Host "Launching $PackageName..."
    & $AdbExe shell am start -n "$PackageName/$MainActivity"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Launch successful!" -ForegroundColor Green
    } else {
        Write-Host "Warning: Failed to launch app automatically." -ForegroundColor Yellow
    }
} else {
    Write-Host "Could not determine package name from export_presets.cfg. Please launch manually."
}

Write-Host "`nWorkflow completed successfully!" -ForegroundColor Green

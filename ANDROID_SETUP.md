# Android Build Setup Guide

This document explains how to set up your Windows environment to build, install, and run the game on an Android device.

## Prerequisites

### 1. Install Java Development Kit (JDK)
- Install **JDK 17** (required for Godot 4.x).
- Recommended: [OpenJDK 17 (Temurin)](https://adoptium.net/temurin/releases/?version=17).
- Set `JAVA_HOME` environment variable to your JDK installation path.
- Add `%JAVA_HOME%\bin` to your system `PATH`.

### 2. Install Android SDK
- Download and install [Android Studio](https://developer.android.com/studio) or use [Command Line Tools](https://developer.android.com/studio#command-line-tools-only).
- Using the SDK Manager (inside Android Studio), install:
    - **Android SDK Platform-Tools**
    - **Android SDK Build-Tools** (latest version)
    - **Android SDK Platform** (API level 34 is recommended)
    - **Android SDK Command-line Tools**
- Set `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) environment variable to your Android SDK path.
- Add `%ANDROID_HOME%\platform-tools` to your system `PATH` (so `adb` is available).
  - *Note: If not set, the scripts will try to find it in the default location: `%LOCALAPPDATA%\Android\Sdk`.*

### 3. Install Godot Export Templates
- Open Godot.
- Go to **Editor > Manage Export Templates**.
- Click **Download and Install** for the current version (4.6.stable.mono).
- **CRITICAL for this project**: You must use the **Mono** (also called **.NET**) templates.
- *Without these, the export will fail with "No export template found".*
- Note: Godot stores templates in `%APPDATA%\Godot\export_templates\<version>\`. The folder name may vary (e.g., `4.6.stable.mono` or `4.6.stable.mono.official`). Our deployment script automatically searches for the best match in several locations:
  - Roaming AppData: `%APPDATA%\Godot\export_templates\`
  - Local AppData: `%LOCALAPPDATA%\Godot\export_templates\`
  - Editor folder (Self-contained mode): `godot\...\editor_data\export_templates\`
  - Any folder specified in `GODOT_TEMPLATES_DIR` or `GODOT_DATA_DIR`.
- You can override this by setting the `GODOT_TEMPLATES_DIR` environment variable to the specific version folder.
- Ensure the folder contains `android_source.zip`, which is required for Godot's Android export.

### 4. Install Android Build Templates (Project-Specific)
- Open this project in Godot.
- Go to **Project > Install Android Build Template**.
- This creates the `android/` folder in your project root with the necessary Gradle files.
- *This is required because the project uses a "Gradle Build" export preset.*

### 5. Enable USB Debugging on Your Phone
1. Go to **Settings > About Phone**.
2. Tap **Build Number** 7 times to enable **Developer Options**.
3. Go to **Settings > System > Developer Options**.
4. Enable **USB Debugging**.
5. Connect your phone to your PC via USB and "Allow" the debugging prompt on the phone.

## Godot 4.6 Mono Android Prerequisites

Building for Android with Godot 4.6 Mono (C#) has specific requirements:

1.  **Mono/ .NET Export Templates**: Ensure you have downloaded the templates specifically for the Mono version of Godot.
2.  **Android Build Template**: Must be installed in the project (**Project > Install Android Build Template**). This project is configured to use a custom build.
3.  **Java SDK (JDK) 17**: Godot 4.6 requires JDK 17 for Android exports.
    -   Set this in **Editor > Editor Settings > Export > Android > Java SDK Path**.
    -   Example path: `C:/Program Files/Eclipse Adoptium/jdk-17.x.x.x-hotspot/`
    -   *Note: If using Android Studio, you can use its bundled JBR, e.g., `C:/Program Files/Android/Android Studio/jbr`.*
4.  **Experimental C# Support**: Godot 4.x C# support for Android is still considered "experimental" but functional.
    -   **Troubleshooting Export**: If the export fails, check `build\android\logs\godot-export-android.log` for the full error output.
    -   The warning `Exporting to Android when using C#/.NET is experimental` is expected. Look for other errors (e.g., Gradle build failures) in the log.
    -   `EditorSettings not instantiated yet` is a common warning in headless mode and can usually be ignored.

## Quick Setup Helper
You can run the following script to open the Godot editor directly to this project for configuration:
```bat
scripts\android\open_godot_for_android_setup.bat
```

## Godot Editor Configuration

1. Open the project in the Godot Editor.
2. Go to **Editor > Editor Settings**.
3. Navigate to **Export > Android**.
4. Set the following paths:
    - **Android Sdk Path**: Path to your Android SDK (e.g., `C:/Users/YourName/AppData/Local/Android/Sdk`).
    - **Debug Keystore**: Path to your debug keystore (usually `C:/Users/YourName/.android/debug.keystore`).
    - **Debug Keystore User**: `androiddebugkey`
    - **Debug Keystore Pass**: `android`
5. (Optional) If you have `adb` and `jarsigner` in your `PATH`, Godot should find them automatically.

## Keystore for Release Builds

To create a release APK, you need a release keystore:
1. Run this command in PowerShell (replace placeholders):
   ```powershell
   keytool -genkey -v -keystore my-release.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
   ```
2. In Godot, go to **Project > Export**.
3. Select the **Android** preset.
4. Under **Keystore**, fill in the **Release** path, user, and password.

## Building and Running

### Method 1: Rider Run Configuration (Recommended)
The easiest way to build and deploy is using the built-in Rider run configuration:
1. Select **Android Deploy (Phone)** from the run configurations dropdown in Rider.
2. Click **Run**.
This will automatically export the debug APK, install it on your connected device, and launch the app.

### Method 2: Command Line Scripts
You can also use the scripts in the project root:

- **`android-deploy.bat`**: One-click build + deploy + launch (debug).
- **`export_android_debug.bat`**: Exports a debug APK to `build/android/`.
- **`export_android_release.bat`**: Exports a release APK to `build/android/`.
- **`install_android.bat`**: Installs the debug APK to a connected device via `adb`.
- **`run_android.bat`**: Launches the installed app on the connected device.

## Troubleshooting

- **`adb` not found**: Ensure Android Platform Tools are installed and in your `PATH`, or `ANDROID_HOME` is set correctly. The scripts also check the default location `%LOCALAPPDATA%\Android\Sdk`. You can also define `sdk.dir` in `android\local.properties`.
- **Export fails with "No export template found"**: Go to **Editor > Manage Export Templates** and install the templates for Godot 4.6 (Mono).
- **Export fails with "Android build template not installed"**: Go to **Project > Install Android Build Template**.
- **Gradle/JDK mismatch**: Ensure you are using JDK 17.
- **Missing Build Templates**: If Godot asks for build templates, go to **Project > Install Android Build Template**.
- **Device not found**: Run `adb devices` in PowerShell to check if your phone is recognized. Ensure USB Debugging is on.
- **Export fails**: Check the console output for specific errors. Often it is a missing SDK component or an incorrect path in Editor Settings.

### If headless export fails with only the experimental message

If the `android-deploy` script or `export_android_debug.bat` fails with:
`ERROR: Cannot export project with preset "Android" due to configuration errors: Exporting to Android when using C#/.NET is experimental.`

...and no other specific errors are shown, it usually means Godot's headless mode cannot find your local Android SDK/JDK settings (which are stored in Editor Settings, not the project) or the export preset is missing required values.

**Steps to fix:**
1. Run `scripts\android\open_godot_and_export_instructions.bat`.
2. This will open the Godot Editor UI.
3. In the Editor, go to **Project > Export**.
4. Select the **Android** preset and click **Export Project** once.
5. Save the APK anywhere. This forces Godot to write the necessary internal configuration.
6. Check **Editor > Editor Settings > Export > Android** and ensure **Android SDK Path** and **Java SDK Path** are set correctly.
7. Close Godot and re-run your `android-deploy` command.
8. If it still fails, check `build\android\logs\godot-export-android.log` for the "Relevant log lines" section added by our enhanced script.

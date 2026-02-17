# Tail Tale Match (Gem Kingdoms)

`Tail Tale Match` is a cross‑platform, story-forward match‑3 puzzle game built in `Godot 4.6 (Mono)`.

This repo includes the game project, assets, level JSON data, and a headless test suite for the core match engine.

## Status

- Version: `0.3.0` (from `project.godot`)
- Main scene: `res://scenes/main.tscn`
- Autoload singletons:
  - `GameManager` (`res://scripts/autoload/game_manager.gd`)
  - `SaveManager` (`res://scripts/autoload/save_manager.gd`)
  - `AudioManager` (`res://scripts/autoload/audio_manager.gd`)

> Note: Several internal docs and test output strings still refer to the older working title `Gem Kingdoms`.

## Run the game (Windows)

### Option A: Use the provided script

1. Double‑click `run_game.bat`.
2. Godot will launch using the included engine binary and open the project at the repo root.

### Option B: Run Godot directly

Run:

```bat
godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64.exe --path .
```

## Open in the Godot editor

1. Launch `godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64.exe`.
2. Use **Import** and select this folder (the one containing `project.godot`).
3. Press **Play** (F5).

## Run tests

Tests are implemented as a Godot scene that runs a GDScript test runner.

### Option A: Use the provided script

Double‑click `run_tests.bat`.

This uses the console executable and runs in headless mode:

```bat
godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64_console.exe --headless --path . res://tests/test_match_engine.tscn
```

> `run_tests.bat` ends with a `pause`, so it’s best for manual runs.

### Option B: Run headless (CI-friendly)

In PowerShell (no pause):

```powershell
& .\godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64_console.exe --headless --path . res://tests/test_match_engine.tscn
exit $LASTEXITCODE
```

## Build & Run on Android (Windows)

For instructions on setting up your environment for Android development, see [ANDROID_SETUP.md](ANDROID_SETUP.md).

Once set up, you can use these scripts:
- `export_android_debug.bat`: Export a debug APK.
- `export_android_release.bat`: Export a release APK.
- `install_android.bat`: Install the debug APK to a connected device.
- `run_android.bat`: Launch the app on the connected device.

## Project structure

- `scenes/`
  - Scene compositions and screens (`scenes/screens/`, `scenes/board/`, `scenes/ui/`).
- `scripts/`
  - `autoload/` — global singletons (navigation/state/save/audio).
  - `board/` — pure match-3 model and engine (`BoardState`, `MatchEngine`, etc.).
  - `progression/` — level loading and progression helpers (e.g., `LevelLoader`).
  - `ui/` — HUD, popups, and UI helpers.
- `data/levels/`
  - Level definitions in JSON organized by chapter (`chapter_01`, `chapter_02`, ...).
- `assets/`
  - Sprites, fonts, audio.
- `tests/`
  - Headless test runner scene + script.

## Where to start reading code

- Entry point: `scenes/main.tscn` → `scripts/main.gd`
- Navigation and flow: `scripts/autoload/game_manager.gd`
- Save data (local JSON in `user://`): `scripts/autoload/save_manager.gd`
- Core gameplay logic (renderer-agnostic):
  - `scripts/board/board_state.gd`
  - `scripts/board/match_engine.gd`
- Level file parser: `scripts/progression/level_loader.gd`

## Design / architecture docs

- `ARCHITECTURE.md` — technical architecture and system breakdown
- `DESIGN_DOCUMENT.md` — gameplay rules, objectives, blockers, meta-progression
- `LEVEL_DESIGN_SCHEMA.md` — level JSON schema and conventions

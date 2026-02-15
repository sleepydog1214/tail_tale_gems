# Gem Kingdoms — Technical Architecture

> Cross-platform match-3 game targeting Android, iOS, Windows 11, and macOS.

---

## 1. Technology Stack Decision

### 1.1 Engine: Godot 4.x (GDScript + C# option)

**Why Godot over alternatives:**

| Criterion | Godot 4 | Unity | Flutter/Flame | Unreal |
|---|---|---|---|---|
| License | MIT (fully free, no royalties) | Runtime fee above threshold | BSD-3 | 5% royalty above $1M |
| 2D performance | Excellent, purpose-built 2D | Good but heavier | Adequate for simple games | Overkill for 2D |
| Cross-platform | Android, iOS, Windows, macOS, Linux, Web | Same | Mobile + desktop (weaker game support) | Same |
| Binary size | ~30–50 MB | ~80–150 MB | ~20–40 MB | 200+ MB |
| Community / match-3 | Growing, good 2D tutorials | Largest | Small for games | Mostly 3D |
| Language | GDScript (Python-like) or C# | C# | Dart | C++ / Blueprints |

**Decision: Godot 4.x with GDScript** for these reasons:
1. Zero licensing cost or royalty — critical for a no-IAP game.
2. Excellent 2D rendering and animation system.
3. Native export to all four target platforms.
4. GDScript is approachable and fast to iterate with.
5. Small binary footprint suits mobile distribution.

C# can be used for performance-critical subsystems (match solver, AI hint
generator) if needed via Godot's C# support.

### 1.2 Alternative Considered: Defold

Defold (King/now independent) is also MIT-licensed and built for 2D. It's a
valid alternative with smaller community. If Godot proves problematic, Defold
is the fallback.

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  ┌─────────┐  ┌──────────┐  ┌────────┐  ┌───────────┐  │
│  │ Board   │  │ Castle   │  │ Story  │  │ UI/Menus  │  │
│  │ Renderer│  │ Renderer │  │ System │  │ & HUD     │  │
│  └────┬────┘  └────┬─────┘  └───┬────┘  └─────┬─────┘  │
│       │            │            │              │         │
├───────┼────────────┼────────────┼──────────────┼─────────┤
│       │       GAME LOGIC LAYER  │              │         │
│  ┌────┴────────────┴────────────┴──────────────┴─────┐  │
│  │                  Game Manager                      │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐           │  │
│  │  │ Match    │ │Progression│ │ Booster  │           │  │
│  │  │ Engine   │ │ Manager  │ │ Manager  │           │  │
│  │  └──────────┘ └──────────┘ └──────────┘           │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐           │  │
│  │  │ Level    │ │ Energy   │ │ Event    │           │  │
│  │  │ Loader   │ │ Manager  │ │ Manager  │           │  │
│  │  └──────────┘ └──────────┘ └──────────┘           │  │
│  └───────────────────────┬───────────────────────────┘  │
│                          │                               │
├──────────────────────────┼───────────────────────────────┤
│                    DATA LAYER                            │
│  ┌──────────┐  ┌─────────┴──┐  ┌──────────────────┐    │
│  │ Local    │  │ Save/Load  │  │ Cloud Sync       │    │
│  │ Storage  │  │ Manager    │  │ (optional server)│    │
│  └──────────┘  └────────────┘  └──────────────────┘    │
│                                                          │
├──────────────────────────────────────────────────────────┤
│                   PLATFORM LAYER                         │
│  ┌────────┐  ┌────────┐  ┌──────────┐  ┌────────────┐  │
│  │Android │  │  iOS   │  │ Windows  │  │   macOS    │  │
│  │Export  │  │ Export │  │  Export  │  │   Export   │  │
│  └────────┘  └────────┘  └──────────┘  └────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Core Systems — Detailed Design

### 3.1 Match Engine

The match engine is the heart of the game. It operates on a pure data model
(no rendering dependency) for testability.

```
class BoardState:
    grid: Array[Array[Cell]]       # 2D array of cells
    width: int
    height: int
    move_count: int
    move_limit: int
    objectives: Array[Objective]
    score: int

class Cell:
    gem_type: GemType              # enum: RUBY, SAPPHIRE, EMERALD, ...
    power_up: PowerUpType          # enum: NONE, ROCKET_H, ROCKET_V, BOMB, PRISM
    blocker: BlockerType           # enum: NONE, CRATE, ICE_1, ICE_2, ICE_3, CHAIN, VASE
    is_empty: bool                 # true for holes in irregular boards
    special_tile: SpecialTile      # enum: NONE, PORTAL_IN, PORTAL_OUT, CONVEYOR_*, NEST
```

**Match detection algorithm:**

1. After every swap, scan the board for groups of 3+ connected same-color gems
   (horizontal and vertical runs).
2. Identify the shape of each match to determine power-up creation:
   - Line of 4 → Rocket
   - L/T of 5 → Bomb
   - Line of 5 → Prism
3. Mark matched gems for removal.
4. Process blocker adjacency hits.
5. Remove gems, apply gravity (with portal/conveyor logic).
6. Spawn new gems from top.
7. Repeat from step 1 (cascade) until no more matches exist.
8. Check objectives and move count.
9. If no valid moves remain and level isn't complete, auto-shuffle.

**Hint system:**
- After 5 seconds of inactivity, highlight a valid move.
- Hint prioritizes moves that create power-ups > moves near objectives >
  random valid move.
- Hint calculation runs in a background thread to avoid frame drops.

### 3.2 Level Loader

Levels are defined in JSON (or a custom compact format) and bundled with the
game. No server required for level data.

```json
{
  "level_id": 1,
  "width": 7,
  "height": 9,
  "move_limit": 25,
  "gem_types": ["RUBY", "SAPPHIRE", "EMERALD", "TOPAZ"],
  "objectives": [
    { "type": "COLLECT_COLOR", "color": "RUBY", "count": 30 }
  ],
  "layout": [
    [1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1]
  ],
  "blockers": [
    { "row": 3, "col": 3, "type": "CRATE" },
    { "row": 3, "col": 4, "type": "CRATE" }
  ],
  "portals": [],
  "conveyors": [],
  "difficulty": "EASY",
  "chapter": 1,
  "room": 1
}
```

Layout values: `0` = empty/blocked cell, `1` = normal cell, `2` = special
tile (details in `special_tiles` array).

### 3.3 Progression Manager

Tracks all player progress:

```
class PlayerProgress:
    current_level: int
    stars_earned: Dictionary[int, int]    # level_id -> stars (1-3)
    total_stars: int
    coins: int
    energy: int
    energy_last_regen_time: int           # unix timestamp
    castle_tasks_completed: Array[String] # task IDs
    current_chapter: int
    current_room: int
    boosters_inventory: Dictionary[String, int]  # booster_type -> count
    achievements: Array[String]
    daily_login_streak: int
    last_login_date: String
    expert_mode_unlocked: bool
    settings: PlayerSettings
```

### 3.4 Energy Manager

```
func get_current_energy() -> int:
    var elapsed = Time.now() - energy_last_regen_time
    var regen_ticks = floor(elapsed / REGEN_INTERVAL_SEC)  # 600 sec = 10 min
    var energy = min(stored_energy + regen_ticks, MAX_ENERGY)  # cap at 15
    return energy

func consume_energy(amount: int) -> bool:
    var current = get_current_energy()
    if current < amount:
        return false
    stored_energy = current - amount
    energy_last_regen_time = Time.now()
    return true

func refund_energy(amount: int):
    stored_energy = min(get_current_energy() + amount, MAX_ENERGY)
```

### 3.5 Event Manager

Handles time-based events (weekly challenges, treasure hunts, infinity rush).

```
class GameEvent:
    event_id: String
    event_type: EventType          # WEEKLY_CHALLENGE, TREASURE_HUNT, INFINITY_RUSH
    start_time: int
    end_time: int
    objectives: Array[EventObjective]
    rewards: Array[Reward]
    progress: Dictionary           # objective_id -> current_count
```

Events are defined in a JSON calendar bundled with the app. Updates can be
pushed via optional cloud sync.

---

## 4. Rendering & Visual Architecture

### 4.1 Scene Tree (Godot)

```
Main
├── GameManager (AutoLoad singleton)
├── Screens
│   ├── MainMenuScreen
│   ├── MapScreen (chapter/level selection)
│   ├── CastleScreen (decoration meta-game)
│   ├── GameScreen
│   │   ├── BoardView
│   │   │   ├── GemGrid (TileMap or Node2D with gem sprites)
│   │   │   ├── BlockerLayer
│   │   │   ├── PowerUpLayer
│   │   │   └── EffectsLayer (particles, animations)
│   │   ├── HUD
│   │   │   ├── MoveCounter
│   │   │   ├── ObjectiveDisplay
│   │   │   ├── ScoreDisplay
│   │   │   └── BoosterToolbar
│   │   └── PauseOverlay
│   ├── StoryScreen (dialogue sequences)
│   ├── EventScreen
│   └── SettingsScreen
└── AudioManager (AutoLoad singleton)
```

### 4.2 Animation System

| Animation | Technique | Duration |
|---|---|---|
| Gem swap | Tween (position lerp) | 0.15s |
| Gem match/destroy | Sprite scale to 0 + particle burst | 0.2s |
| Gem fall (gravity) | Tween with slight bounce ease | 0.1s per row |
| Power-up activation | Animated sprite + screen flash | 0.3–0.5s |
| Cascade chain | Sequential with 0.05s overlap | Variable |
| Castle task completion | Animated sprite swap + particle confetti | 1.0s |

All animations are cancellable/skippable in reduced-motion mode.

### 4.3 Art Style

- **Bright, saturated 2D** with clean outlines (similar to Candy Crush /
  Royal Match aesthetic but with its own identity).
- Gems are simple geometric shapes with inner glow and face/personality
  (subtle expressions when matched).
- Castle scenes are illustrated 2D backgrounds with layered parallax.
- UI follows Material Design 3 principles adapted for game context.
- All art is vector-based (SVG → rasterized at export) for resolution
  independence.

### 4.4 Resolution & Scaling

| Platform | Target Resolution | Scaling |
|---|---|---|
| Mobile (phone) | 1080×1920 (portrait) | Auto-scale with safe areas |
| Mobile (tablet) | 1536×2048 (portrait) | Wider board margins |
| Desktop | 1280×720 minimum, scales to 4K | Windowed, resizable |

The game uses a **viewport stretch mode** with `canvas_items` stretch aspect
to maintain pixel-perfect 2D scaling across all resolutions.

---

## 5. Data Storage & Cloud Sync

### 5.1 Local Storage

- **Format:** Encrypted JSON file in the app's private storage.
- **Location:**
  - Android: `user://save_data.json` (maps to internal app storage)
  - iOS: `user://save_data.json` (maps to app sandbox/Documents)
  - Windows: `%APPDATA%/GemKingdoms/save_data.json`
  - macOS: `~/Library/Application Support/GemKingdoms/save_data.json`
- **Encryption:** AES-256 with a device-derived key to prevent trivial save
  editing (not DRM, just integrity).
- **Auto-save:** After every level completion, castle task, and booster use.

### 5.2 Cloud Sync (Phase 2)

Cloud sync is optional and not required for MVP.

**Architecture:**
```
Client  ←→  REST API  ←→  Database
              │
         Auth Service
         (email/OAuth)
```

- **Backend:** Lightweight REST API (Go, Rust, or Node.js) deployed on a
  VPS or serverless platform (AWS Lambda / Cloudflare Workers).
- **Database:** PostgreSQL for player data, Redis for session/energy state.
- **Auth:** Email + password, or OAuth (Google, Apple Sign-In).
- **Sync strategy:** Last-write-wins with conflict detection. On conflict,
  present both saves to the player and let them choose.
- **Cost:** Minimal — player data is small (~10 KB per player). A $5/month
  VPS can serve thousands of players.

### 5.3 Save Data Schema

```json
{
  "version": 1,
  "player_id": "uuid-here",
  "created_at": "2026-01-15T00:00:00Z",
  "last_saved_at": "2026-02-15T12:00:00Z",
  "progress": {
    "current_level": 47,
    "levels": {
      "1": { "stars": 3, "best_score": 12500, "attempts": 1 },
      "2": { "stars": 2, "best_score": 9800, "attempts": 2 }
    },
    "total_stars": 98,
    "coins": 3200,
    "energy": 12,
    "energy_regen_timestamp": 1739620800
  },
  "castle": {
    "current_chapter": 2,
    "current_room": 3,
    "completed_tasks": ["ch1_r1_t1", "ch1_r1_t2", "ch1_r1_t3", "ch1_r1_t4"]
  },
  "inventory": {
    "booster_rocket": 3,
    "booster_bomb": 1,
    "booster_prism": 0,
    "booster_extra_moves": 2,
    "booster_hammer": 4,
    "booster_shuffle": 2,
    "booster_row_blast": 1,
    "booster_col_blast": 1
  },
  "daily": {
    "login_streak": 5,
    "last_login": "2026-02-15",
    "quests": [
      { "id": "win_3_levels", "progress": 2, "target": 3, "completed": false },
      { "id": "create_5_rockets", "progress": 5, "target": 5, "completed": true }
    ]
  },
  "settings": {
    "music_volume": 0.7,
    "sfx_volume": 1.0,
    "colorblind_mode": false,
    "reduced_motion": false,
    "language": "en"
  },
  "stats": {
    "total_levels_played": 120,
    "total_wins": 98,
    "total_losses": 22,
    "total_boosters_used": 15,
    "longest_win_streak": 12,
    "play_time_minutes": 480
  }
}
```

---

## 6. Input Handling

### 6.1 Touch (Mobile)

- **Swipe:** Drag a gem in a cardinal direction to swap.
  - Minimum swipe distance: 20px (scaled for DPI).
  - Swipe direction locked to the dominant axis.
- **Tap:** Activate a booster from the toolbar, then tap a target cell.
- **Long press:** Show gem/blocker info tooltip.

### 6.2 Mouse (Desktop)

- **Click + drag:** Same as swipe.
- **Click:** Select gem, then click adjacent gem to swap (alternative to drag).
- **Right-click:** Cancel booster selection.
- **Scroll wheel:** Scroll castle view, level map.

### 6.3 Keyboard (Desktop)

| Key | Action |
|---|---|
| Arrow keys | Move selection cursor on board |
| Space / Enter | Confirm swap / activate |
| 1–4 | Select booster from toolbar |
| Escape | Pause / back |
| R | Restart level (with confirmation) |
| H | Request hint |

---

## 7. Audio Design

### 7.1 Music

- **Main menu:** Gentle orchestral theme (harp, strings).
- **Gameplay:** Light, upbeat loop per chapter theme (varies by castle area).
- **Castle decoration:** Calm ambient with occasional melodic accents.
- **Events:** Unique tracks for special events.
- Crossfade between tracks (1.5s fade).

### 7.2 Sound Effects

| Event | Sound |
|---|---|
| Gem swap | Soft click |
| Match 3 | Chime (pitch varies by combo length) |
| Match 4+ | Ascending chime |
| Cascade | Rapid ascending chimes with increasing pitch |
| Rocket activation | Whoosh |
| Bomb activation | Deep thud + scatter |
| Prism activation | Magical shimmer |
| Level win | Fanfare |
| Level fail | Descending tone (not punishing) |
| Star earned | Coin-like ding |
| Castle task | Construction hammer + sparkle |

### 7.3 Implementation

- Audio files: OGG Vorbis for music (streaming), WAV for short SFX.
- Audio bus layout: Master → Music, Master → SFX, Master → UI.
- Volume controlled independently per bus.

---

## 8. Project Structure (Godot)

```
gem_kingdoms/
├── project.godot
├── export_presets.cfg
│
├── assets/
│   ├── sprites/
│   │   ├── gems/               # gem textures (6 colors × normal + power-up states)
│   │   ├── blockers/           # crate, ice, chain, vase sprites
│   │   ├── effects/            # particle textures, explosions
│   │   ├── castle/             # castle room backgrounds, furniture, decor items
│   │   ├── characters/         # character portraits, expressions
│   │   └── ui/                 # buttons, panels, icons
│   ├── audio/
│   │   ├── music/              # .ogg files
│   │   └── sfx/                # .wav files
│   └── fonts/
│
├── scenes/
│   ├── main.tscn               # root scene
│   ├── screens/
│   │   ├── main_menu.tscn
│   │   ├── level_map.tscn
│   │   ├── castle_view.tscn
│   │   ├── game_screen.tscn
│   │   ├── story_dialogue.tscn
│   │   └── settings.tscn
│   ├── board/
│   │   ├── board_view.tscn
│   │   ├── gem.tscn
│   │   ├── blocker.tscn
│   │   └── power_up_effect.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── booster_toolbar.tscn
│   │   ├── popup_dialog.tscn
│   │   └── star_display.tscn
│   └── castle/
│       ├── room_view.tscn
│       └── task_item.tscn
│
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd     # global state, screen transitions
│   │   ├── audio_manager.gd    # music/sfx playback
│   │   ├── save_manager.gd     # local save/load + encryption
│   │   └── event_manager.gd    # daily/weekly event logic
│   ├── board/
│   │   ├── board_state.gd      # pure data model (no rendering)
│   │   ├── match_engine.gd     # match detection, gravity, cascades
│   │   ├── board_controller.gd # input handling, animation coordination
│   │   ├── hint_system.gd      # AI hint generation
│   │   └── objective_tracker.gd
│   ├── progression/
│   │   ├── level_loader.gd     # JSON → BoardState
│   │   ├── progression_manager.gd
│   │   ├── energy_manager.gd
│   │   └── booster_manager.gd
│   ├── castle/
│   │   ├── castle_manager.gd
│   │   ├── room_controller.gd
│   │   └── decoration_data.gd
│   ├── story/
│   │   ├── dialogue_system.gd
│   │   └── story_data.gd
│   └── ui/
│       ├── screen_manager.gd
│       └── popup_manager.gd
│
├── data/
│   ├── levels/
│   │   ├── chapter_01/
│   │   │   ├── level_001.json
│   │   │   ├── level_002.json
│   │   │   └── ...
│   │   └── chapter_02/
│   │       └── ...
│   ├── castle/
│   │   ├── chapters.json       # chapter/room/task definitions
│   │   └── decorations.json    # visual data for each decoration task
│   ├── story/
│   │   └── dialogues.json      # all dialogue text, keyed by trigger
│   ├── events/
│   │   └── event_calendar.json
│   └── balance/
│       ├── difficulty_curve.json   # move limits, star thresholds
│       ├── economy.json            # coin/booster earn rates
│       └── energy_config.json
│
└── tests/
    ├── test_match_engine.gd
    ├── test_board_state.gd
    ├── test_progression.gd
    ├── test_energy.gd
    └── test_level_loader.gd
```

---

## 9. Build & CI/CD Pipeline

### 9.1 Version Control

- Git repository (GitHub or GitLab).
- Branch strategy: `main` (release), `develop` (integration), `feature/*`.
- Level data and balance JSONs are version-controlled alongside code.

### 9.2 Build Pipeline

```
Push to develop
    │
    ├─→ Run GDScript linter (gdtoolkit)
    ├─→ Run unit tests (GUT framework)
    │
    ▼
Merge to main (tagged release)
    │
    ├─→ Export Android APK + AAB (Godot CLI export)
    ├─→ Export iOS IPA (requires macOS runner)
    ├─→ Export Windows EXE (NSIS installer or MSIX)
    ├─→ Export macOS APP (Universal Binary, notarized)
    │
    ▼
Upload to stores / release page
```

### 9.3 CI Tools

- **GitHub Actions** with Godot Docker image for Linux/Windows/Android builds.
- **macOS runner** (self-hosted or GitHub-hosted) for iOS and macOS builds.
- **Fastlane** for App Store and Google Play deployment automation.

### 9.4 Testing Strategy

| Layer | Tool | Scope |
|---|---|---|
| Unit tests | GUT (Godot Unit Test) | Match engine, progression, energy, level loading |
| Integration tests | GUT + custom scenes | Full level playthrough simulation |
| Visual regression | Screenshot comparison | Board rendering, UI layouts |
| Manual QA | Device matrix | Touch input, performance, platform-specific bugs |
| Balance testing | Automated solver | Run 1000 simulations per level to verify win rates |

The automated solver is critical: it plays each level thousands of times with
random (but legal) moves to verify that the design win rate targets are met.
Levels that fall below threshold get flagged for redesign.

---

## 10. Performance Targets

| Metric | Target |
|---|---|
| Frame rate | 60 FPS constant (all platforms) |
| Level load time | < 0.5s |
| App launch to menu | < 2s (mobile), < 1s (desktop) |
| Memory usage | < 200 MB (mobile), < 400 MB (desktop) |
| APK size | < 80 MB |
| Battery impact | < 5% per hour of play (mobile) |

### 10.1 Optimization Strategies

- **Object pooling** for gems and particles (avoid GC pressure).
- **Sprite atlases** to minimize draw calls.
- **Lazy loading** for castle scenes and story assets (only load current
  chapter's assets).
- **Background thread** for hint calculation and match solving.
- **LOD for particles**: fewer particles on low-end devices (auto-detected).

---

## 11. Security Considerations

- Save files encrypted with AES-256 to prevent trivial score/coin editing.
- No server-authoritative gameplay (single-player game) — cheating only
  affects the cheater's own experience.
- If cloud sync is added: server validates basic plausibility (e.g., can't
  have 1 million stars with 5 levels played) but doesn't need real-time
  anti-cheat.
- No user-generated content, so no moderation concerns.
- Privacy: no analytics/telemetry by default. Optional opt-in crash reporting
  only.

---

## 12. Localization

- All player-facing text is externalized to translation files.
- Godot's built-in `TranslationServer` with CSV or PO files.
- Launch languages: English, Spanish, French, German, Portuguese, Japanese,
  Korean, Chinese (Simplified).
- RTL language support (Arabic, Hebrew) planned for post-launch.
- Text in art assets avoided — use overlays instead.

---

## 13. Development Phases

### Phase 1: Core Prototype (Vertical Slice)

**Goal:** Playable match-3 board with full match logic, one level, basic UI.

Deliverables:
- Match engine with gravity, cascades, power-ups.
- Single hardcoded level playable on desktop.
- Basic gem sprites (placeholder art OK).
- Move counter, objective display, win/fail detection.
- Unit tests for match engine.

### Phase 2: Progression & Meta

**Goal:** Multiple levels, star system, castle decoration, energy.

Deliverables:
- Level loader reading from JSON.
- 20 levels across 2 chapters.
- Star rating and star spending on castle tasks.
- Energy system.
- Coin system with level rewards.
- Save/load to local storage.
- Basic castle view with task completion.

### Phase 3: Polish & Content

**Goal:** Full game feel, more content, story, events.

Deliverables:
- Booster system (pre-game and in-game).
- Hint system.
- Story dialogue system with character art.
- 50+ levels, 5 chapters.
- All blocker types implemented.
- Weekly challenge event system.
- Daily login rewards.
- Sound effects and music.
- Animations and particle effects.

### Phase 4: Cross-Platform & Release

**Goal:** Ship on all four platforms.

Deliverables:
- Android export, testing on device matrix.
- iOS export, TestFlight.
- Windows export, installer.
- macOS export, notarization.
- Platform-specific input handling verified.
- Performance optimization pass.
- Accessibility features (colorblind, reduced motion).
- Localization for launch languages.
- App store listings, screenshots, descriptions.

### Phase 5: Post-Launch

**Goal:** Live content, community, cloud sync.

Deliverables:
- Cloud save backend.
- 100+ additional levels.
- New chapters and castle areas.
- Treasure Hunt events.
- Expert mode.
- Community feedback integration.

---

## 14. Risk Register

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| Godot 4 mobile performance issues | High | Medium | Profile early on target devices; fallback to Defold if needed. |
| Level design bottleneck (designing thousands of fun levels) | High | High | Build a level editor tool early; invest in automated balance testing. |
| iOS export complexity (certificates, provisioning) | Medium | Medium | Use Fastlane; document the process thoroughly. |
| Cloud sync conflicts | Medium | Low | Phase 2 feature; start with local-only. Use last-write-wins with manual conflict resolution. |
| Art asset production volume | High | High | Use simple, clean art style; consider procedural decoration variants. |
| Retention without monetization pressure | Medium | Medium | Focus on intrinsic motivation: mastery, story, collection. Difficulty curve must be carefully tuned. |

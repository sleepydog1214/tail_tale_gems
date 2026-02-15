# Gem Kingdoms — Game Design Document

> A free-to-play, no-IAP match-3 puzzle game with castle-renovation meta-progression.
> Platforms: Android, iOS, Windows 11, macOS.

---

## 1. Game Overview

### 1.1 Concept

Gem Kingdoms is a story-driven match-3 puzzle game where players complete
tile-matching levels to earn stars and help Queen Elara restore her crumbling
kingdom — room by room, garden by garden, chapter by chapter. Unlike commercial
match-3 games, **there are zero in-app purchases**. All progression, boosters,
and cosmetics are earned through gameplay.

### 1.2 Target Audience

- Casual puzzle players aged 16+
- Fans of match-3 games who dislike pay-to-win mechanics
- Cross-platform players who want to pick up on phone or desktop seamlessly

### 1.3 Pillars

| Pillar | Meaning |
|---|---|
| **Fair by design** | Every level is beatable without boosters. Difficulty comes from skill, not monetization pressure. |
| **Progression that respects time** | Energy regenerates generously. No paywalls. Playing well is always rewarded. |
| **Story & charm** | Characters, dialogue, and castle decoration give the game personality beyond raw puzzles. |
| **Cross-platform parity** | Same account, same progress, same experience on every device. |

---

## 2. Core Gameplay — Match-3 Rules

### 2.1 Board Basics

- The board is a grid (typically 7×9, but level design can vary: 6×8, 8×10,
  irregular shapes with blocked cells).
- The grid is filled with **gems** of 5–6 colors (Ruby, Sapphire, Emerald,
  Topaz, Amethyst, and optionally Diamond for later chapters).
- Gravity pulls gems downward; new gems spawn from the top.

### 2.2 Matching

| Action | Result |
|---|---|
| Swap two adjacent gems | If the swap creates a line of 3+ same-color gems, they are cleared. Otherwise the swap reverses. |
| Match 3 | Gems cleared, score awarded. |
| Match 4 (line) | Creates a **Rocket** (directional clear). |
| Match 5 (L or T shape) | Creates a **Bomb** (area clear). |
| Match 5 (straight line) | Creates a **Prism** (color bomb — clears all gems of a chosen color). |

### 2.3 Power-Ups (Board-Created)

| Power-Up | Creation | Effect |
|---|---|---|
| **Rocket** | Match 4 in a line | Clears the entire row *or* column (direction based on swipe). |
| **Bomb** | Match 5 in L/T shape | Clears a 3×3 area around it when activated. |
| **Prism** | Match 5 in a straight line | Swap with any gem to clear every gem of that color on the board. |

### 2.4 Power-Up Combinations

Swapping two power-ups together creates enhanced effects:

| Combination | Effect |
|---|---|
| Rocket + Rocket | Clears both the full row AND full column through the intersection. |
| Rocket + Bomb | Clears 3 rows AND 3 columns through the intersection. |
| Bomb + Bomb | Clears a 5×5 area. |
| Rocket + Prism | Turns all gems of the Rocket's color into Rockets, then detonates them. |
| Bomb + Prism | Turns all gems of the Bomb's color into Bombs, then detonates them. |
| Prism + Prism | Clears the entire board. |

### 2.5 Level Objectives

Each level has 1–3 objectives drawn from a pool:

| Objective Type | Description |
|---|---|
| **Collect colors** | Clear N gems of specified color(s). |
| **Remove blockers** | Destroy vases, crates, ice, chains, etc. |
| **Drop items** | Guide specific items (crowns, keys) to the bottom of the board. |
| **Spread coverage** | Match on every tile to "paint" the board (like grass/carpet spreading). |
| **Collect specials** | Create and activate N Rockets/Bombs/Prisms. |

### 2.6 Blockers & Special Tiles

| Element | Behavior |
|---|---|
| **Crate** (1-hit) | Destroyed when an adjacent match is made. |
| **Reinforced Crate** (2-hit) | Takes 2 adjacent matches to destroy. |
| **Ice** (1–3 layers) | Freezes a gem in place; each adjacent match removes one layer. |
| **Chain** | Locks a gem; must match the chained gem itself to free it. |
| **Vase** | Occupies a cell; destroyed by adjacent match or power-up. May contain an item. |
| **Portals** | Gems entering one portal exit another — creates non-linear gravity. |
| **Conveyor belts** | Shift gems in a direction each turn. |
| **Royal Egg** | Must be guided to a nest tile; moves down one row per turn when support is cleared. |

New blockers are introduced roughly every 20 levels to keep the game fresh.

### 2.7 Move Limit

- Every level has a fixed move count (shown top-right).
- Running out of moves = level failure.
- Remaining moves at level completion convert to bonus score and influence
  star rating.

---

## 3. Progression Systems

### 3.1 Stars

| Performance | Stars Earned |
|---|---|
| Complete level (any remaining moves) | 1 star |
| Complete with ≥ 33% moves remaining | 2 stars |
| Complete with ≥ 66% moves remaining | 3 stars |

Stars are the primary meta-currency. They are spent on castle decoration tasks.

### 3.2 Castle Meta-Game

The castle is divided into **Chapters → Rooms → Tasks**.

```
Kingdom
├── Chapter 1: The Grand Hall (5 rooms)
│   ├── Room 1: Entrance Foyer (4 tasks, costs 4 stars)
│   ├── Room 2: Main Hall (5 tasks, costs 5 stars)
│   ├── Room 3: Chandelier Gallery (5 tasks, costs 6 stars)
│   ├── Room 4: Throne Room (6 tasks, costs 7 stars)
│   └── Room 5: Royal Portrait Wing (6 tasks, costs 8 stars)
├── Chapter 2: The Royal Gardens (5 rooms)
│   └── ...
├── Chapter 3: The Kitchen & Pantry
│   └── ...
└── ... (20+ chapters planned)
```

- Each **task** costs 1 star (e.g., "Repair the chandelier," "Place the rug").
- Completing a task triggers a short decoration animation and optional dialogue.
- Completing a **room** unlocks a mini-cutscene and a gameplay reward (new
  booster type, permanent perk, or cosmetic).
- Completing a **chapter** unlocks the next chapter and grants a major reward
  (30-minute unlimited energy, rare booster pack, new gem skin).

### 3.3 Coins (Soft Currency)

Earned from:
- Winning a level: 50–150 coins (scales with difficulty).
- Near-win bonus: 10–30 coins if you fail with ≤ 2 objectives remaining.
- Daily quests: 100–500 coins per quest.
- Milestone rewards: lump sums at chapter completions.

Spent on:
- Extra moves (+5 moves for 200 coins when you fail a level).
- Pre-game boosters (see §4).
- Cosmetic unlocks (gem skins, board themes — purely visual).

### 3.4 Energy (Stamina)

| Parameter | Value |
|---|---|
| Max energy | 15 |
| Energy cost per attempt | 1 |
| Regen rate | 1 energy per 10 minutes |
| Win refund | Full refund (winning is free) |
| Chapter completion bonus | Full refill + 30 min unlimited |
| Daily login bonus | +5 energy |

Design intent: A player who wins most levels can play indefinitely. Energy only
drains on failures, encouraging skill improvement rather than grinding.

### 3.5 Level Gating

- Levels unlock linearly (beat level N to access level N+1).
- Every 50 levels, a **gate** requires a minimum star count to proceed.
  - Gate at level 50: 40 stars needed (out of max 150 possible).
  - Gate at level 100: 90 stars.
  - Gate at level 150: 150 stars.
  - This encourages replaying earlier levels for better star ratings but is
    very achievable for average players.

### 3.6 Difficulty Tracks

| Track | Unlock | Characteristics |
|---|---|---|
| **Standard** | Default | Balanced move counts. 1–3 stars per win. |
| **Expert** | After completing Chapter 3 | Reduced moves, harder layouts. 2–4 stars per win, 1.5× coins. |

Expert track provides optional challenge for skilled players without gating
standard progression.

---

## 4. Boosters & Power-Ups (Earn-Only)

### 4.1 Pre-Game Boosters

Placed on the board before the level starts. Max 2 per level.

| Booster | Effect | Earn Sources |
|---|---|---|
| **Starting Rocket** | A Rocket is pre-placed on a random tile. | Win streaks (3 in a row), daily quests. |
| **Starting Bomb** | A Bomb is pre-placed. | Milestone rewards, weekly events. |
| **Starting Prism** | A Prism is pre-placed. | Rare: chapter completion reward. |
| **+3 Moves** | Start the level with 3 extra moves. | Daily login (day 5+), coin purchase (300 coins). |

### 4.2 In-Game Boosters

Activated during play from a toolbar. Each has a limited inventory.

| Booster | Effect | Earn Sources |
|---|---|---|
| **Royal Hammer** | Destroy any single tile/blocker. | Quests, milestones. Carry max 5. |
| **Shuffle** | Randomize all gems on the board (no move cost). | Quests. Carry max 3. |
| **Row Blast** | Clear an entire row of your choice. | Events, milestones. Carry max 3. |
| **Column Blast** | Clear an entire column of your choice. | Events, milestones. Carry max 3. |

### 4.3 Booster Economy

- Boosters are earned at a steady drip, never purchased with real money.
- Typical earn rate: ~2–3 boosters per play session (30–60 min).
- Hard levels are tuned to be winnable without boosters (tested at 90%+ win
  rate without boosters in playtesting target).
- Boosters provide comfort, not necessity.

---

## 5. Events & Recurring Content

### 5.1 Weekly Challenge

- 7-day cycle, resets Monday.
- Objectives: "Win 15 levels," "Create 20 Rockets," "Beat 3 Hard levels."
- Rewards: Coins, boosters, exclusive gem skin.

### 5.2 Treasure Hunt (Bi-Weekly)

- Special set of 10 themed levels (e.g., "Underwater Ruins," "Clocktower").
- Unique mechanics or boosted blocker density.
- Completing all 10 grants a large star bonus and cosmetic reward.

### 5.3 Infinity Rush (Chapter Completion Reward)

- 30 minutes of unlimited energy + bonus coin multiplier.
- Triggered automatically when a chapter is completed.
- Encourages a satisfying "victory lap" session.

### 5.4 Daily Login Rewards

| Day | Reward |
|---|---|
| 1 | 100 coins |
| 2 | 1 Royal Hammer |
| 3 | 200 coins |
| 4 | 1 Starting Rocket |
| 5 | +5 energy |
| 6 | 1 Shuffle |
| 7 | 500 coins + 1 Starting Prism |

Cycle repeats. Streak bonuses: 14-day streak doubles Day 7 reward.

---

## 6. Story & Characters

### 6.1 Setting

The Kingdom of Aurelia — a once-grand realm fallen into disrepair after a
magical storm. Queen Elara has returned to restore it.

### 6.2 Main Characters

| Character | Role | Personality |
|---|---|---|
| **Queen Elara** | Player's avatar & narrator | Determined, warm, witty. |
| **Percival** | Royal butler | Fussy, detail-oriented, comedic relief. |
| **Maple** | Castle cat | Appears in cutscenes, reacts to decoration. Has no dialogue but is very expressive. |
| **Gideon** | Royal architect | Introduces new rooms, explains renovation tasks. |
| **Bramble** | Gardener | Appears in garden chapters, loves plants, hates bugs (ironic for garden levels). |

### 6.3 Story Delivery

- Short dialogue sequences (2–4 lines) between levels.
- Room completion cutscenes (5–10 seconds, animated).
- Chapter completion: longer narrative beat revealing more kingdom lore.
- All story is skippable.

---

## 7. Monetization: None (By Design)

This game has **no in-app purchases, no ads, and no premium currency**.

Revenue model options (if desired in the future):
- One-time purchase price ($4.99–$9.99) on app stores.
- Cosmetic-only DLC packs (new gem skins, castle themes) — never gameplay
  advantage.
- "Supporter" tier: optional tip jar that grants a cosmetic badge only.

The game must be fully playable and completable without spending any money.

---

## 8. Accessibility & Settings

- Colorblind mode: gems have distinct shapes in addition to colors.
- Reduced motion mode: disables particle effects and animations.
- Scalable UI: supports font size adjustment, touch target sizes meet
  WCAG 2.1 AA guidelines.
- One-handed play: all interactions are single-tap/swipe.
- Screen reader hints for menus and navigation (not gameplay board).
- Offline play: full gameplay available offline; sync on reconnect.

---

## 9. Platform-Specific Notes

| Platform | Distribution | Input | Notes |
|---|---|---|---|
| Android | Google Play Store / APK | Touch | Target API 33+, min API 26 (Android 8.0). |
| iOS | App Store | Touch | Min iOS 15. |
| Windows 11 | Microsoft Store / direct download | Mouse + keyboard shortcuts | Window resizable, min 1280×720. |
| macOS | Mac App Store / direct download | Mouse + trackpad + keyboard | Min macOS 12. Universal binary (Intel + Apple Silicon). |

Cloud save syncs progress across all platforms via player account.

---

## 10. Success Metrics (Internal)

| Metric | Target |
|---|---|
| Level completion rate (no boosters) | ≥ 85% on Standard, ≥ 60% on Expert |
| Average session length | 15–30 minutes |
| Day-7 retention | ≥ 40% |
| Day-30 retention | ≥ 20% |
| Levels per session | 5–10 |
| Star gate pass rate | ≥ 95% of active players pass each gate within 3 days |

# Gem Kingdoms — Level Design Schema & Balance Guide

> Reference for level designers and the automated balance testing system.

---

## 1. Level Data Format (Full Specification)

### 1.1 Level JSON Schema

```json
{
  "$schema": "level_schema_v1",
  "level_id": 15,
  "chapter": 1,
  "room": 3,
  "difficulty": "MEDIUM",
  "title": "Crystal Corridor",

  "board": {
    "width": 7,
    "height": 9,
    "layout": [
      [1,1,0,1,1,0,1],
      [1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1],
      [1,1,0,1,1,0,1]
    ],
    "gem_pool": ["RUBY", "SAPPHIRE", "EMERALD", "TOPAZ"],
    "gravity_direction": "DOWN"
  },

  "move_limit": 22,

  "objectives": [
    {
      "type": "COLLECT_COLOR",
      "params": { "color": "RUBY", "count": 25 }
    },
    {
      "type": "REMOVE_BLOCKER",
      "params": { "blocker": "CRATE", "count": 8 }
    }
  ],

  "blockers": [
    { "row": 2, "col": 1, "type": "CRATE", "hp": 1 },
    { "row": 2, "col": 5, "type": "CRATE", "hp": 1 },
    { "row": 3, "col": 2, "type": "CRATE", "hp": 1 },
    { "row": 3, "col": 4, "type": "CRATE", "hp": 1 },
    { "row": 5, "col": 1, "type": "ICE", "hp": 2 },
    { "row": 5, "col": 5, "type": "ICE", "hp": 2 },
    { "row": 6, "col": 2, "type": "CRATE", "hp": 1 },
    { "row": 6, "col": 3, "type": "CRATE", "hp": 1 },
    { "row": 6, "col": 4, "type": "CRATE", "hp": 1 },
    { "row": 7, "col": 3, "type": "CRATE", "hp": 1 }
  ],

  "special_tiles": [],

  "portals": [],

  "conveyors": [],

  "spawners": [
    {
      "col": 0, "row": 0,
      "gem_weights": { "RUBY": 30, "SAPPHIRE": 25, "EMERALD": 25, "TOPAZ": 20 }
    }
  ],

  "rewards": {
    "coins_base": 80,
    "coins_per_remaining_move": 10,
    "star_thresholds": {
      "1_star": 0,
      "2_star": 7,
      "3_star": 14
    }
  },

  "metadata": {
    "designer": "auto",
    "created_at": "2026-02-15",
    "solver_win_rate": 0.91,
    "solver_avg_moves_remaining": 4.2,
    "solver_iterations": 10000
  }
}
```

### 1.2 Layout Cell Values

| Value | Meaning |
|---|---|
| `0` | Blocked cell (hole in the board, no gem can occupy) |
| `1` | Normal playable cell |
| `2` | Special tile (referenced by `special_tiles` array) |

### 1.3 Objective Types

| Type | Parameters | Description |
|---|---|---|
| `COLLECT_COLOR` | `color`, `count` | Clear N gems of a specific color. |
| `REMOVE_BLOCKER` | `blocker`, `count` | Destroy N blockers of a type. |
| `DROP_ITEM` | `item`, `count`, `target_row` | Guide N items to a target row (usually bottom). |
| `SPREAD_COVERAGE` | `percentage` | Match on X% of all playable cells. |
| `CREATE_POWERUP` | `powerup`, `count` | Create N power-ups of a type. |
| `SCORE_TARGET` | `score` | Reach a total score. |
| `COMBO_CHAIN` | `min_cascade`, `count` | Trigger N cascades of at least M length. |

### 1.4 Blocker Types

| Type | HP | Behavior |
|---|---|---|
| `CRATE` | 1 | Destroyed by adjacent match. Occupies cell (no gem beneath). |
| `REINFORCED_CRATE` | 2–3 | Like crate but takes multiple hits. Visual layers peel off. |
| `ICE` | 1–3 | Freezes a gem in place. Gem is still visible but can't be swapped. Adjacent match removes one layer. |
| `CHAIN` | 1 | Locks a gem. Must match the chained gem itself (not adjacent) to remove. |
| `VASE` | 1–2 | Occupies cell. May contain a collectible item that drops when destroyed. |
| `STONE` | ∞ | Indestructible wall. Only removable by power-ups. |
| `ROYAL_EGG` | special | Must be dropped to a nest tile. Falls one row when support below is cleared. |

### 1.5 Special Tile Types

| Type | Behavior |
|---|---|
| `PORTAL_IN` | Gem entering this cell exits at the linked `PORTAL_OUT`. |
| `PORTAL_OUT` | Exit point for portal. Requires `link_id` to pair with entrance. |
| `CONVEYOR_LEFT/RIGHT/UP/DOWN` | Shifts all gems on belt tiles one step per turn. |
| `NEST` | Target for `ROYAL_EGG` — egg reaching this tile completes that objective. |
| `GENERATOR` | Spawns a specific item or blocker every N turns. |

---

## 2. Difficulty Curve & Balance Tables

### 2.1 Level Difficulty Tiers

| Tier | Level Range (approx) | Move Budget | Gem Colors | Blocker Types | Target Win Rate |
|---|---|---|---|---|---|
| Tutorial | 1–5 | 30–40 | 3–4 | None | 98% |
| Easy | 6–20 | 25–35 | 4 | Crate | 95% |
| Medium | 21–50 | 20–30 | 4–5 | Crate, Ice | 90% |
| Hard | 51–100 | 18–25 | 5 | Crate, Ice, Chain, Vase | 85% |
| Very Hard | 101–200 | 15–22 | 5–6 | All standard | 80% |
| Expert | 201+ | 12–20 | 5–6 | All + special mechanics | 70% |

"Win rate" = percentage of random-but-legal-play simulations that complete
the level. A skilled human should exceed these rates.

### 2.2 Coin Rewards by Difficulty

| Difficulty | Base Coins | Per Remaining Move | Near-Win Bonus |
|---|---|---|---|
| Tutorial | 50 | 5 | 10 |
| Easy | 60 | 8 | 15 |
| Medium | 80 | 10 | 20 |
| Hard | 100 | 12 | 30 |
| Very Hard | 120 | 15 | 40 |
| Expert | 150 | 20 | 50 |

### 2.3 Star Thresholds (Moves Remaining)

Stars are awarded based on how many moves are left when the level is completed.

| Stars | Moves Remaining |
|---|---|
| 1 star | 0+ (just complete it) |
| 2 stars | ≥ 33% of move limit remaining |
| 3 stars | ≥ 66% of move limit remaining |

Example: A level with 24 moves → 2 stars at 8+ remaining, 3 stars at 16+ remaining.

### 2.4 Energy Economy

| Event | Energy Change |
|---|---|
| Attempt a level | −1 |
| Win a level | +1 (net zero) |
| Fail a level | 0 (the −1 already spent) |
| Time regen | +1 every 10 min |
| Daily login | +5 |
| Chapter completion | Full refill (15) + 30 min unlimited |
| Watch practice mode | 0 (free) |

A player failing 50% of attempts with 15 energy: can play ~30 levels before
waiting. At 10 min regen, full refill = 2.5 hours.

### 2.5 Booster Distribution

Target: ~2–3 boosters earned per 30-minute session.

| Source | Frequency | Rewards |
|---|---|---|
| Daily login (Day 1–7 cycle) | Daily | 1 booster every other day |
| Daily quest: "Win 3 levels" | Daily | 1 Hammer or 100 coins |
| Daily quest: "Create 5 Rockets" | Daily | 1 Starting Rocket |
| Win streak (3 in a row) | Per streak | 1 random pre-game booster |
| Win streak (5 in a row) | Per streak | 1 Shuffle + 200 coins |
| Room completion | ~Every 5 levels | 2 boosters + 300 coins |
| Chapter completion | ~Every 25 levels | 1 of each booster type |
| Weekly challenge | Weekly | 3 boosters + 500 coins + gem skin |
| Treasure Hunt (10 levels) | Bi-weekly | 5 boosters + 1000 coins |

---

## 3. First 30 Levels — Detailed Design

### 3.1 Tutorial Sequence (Levels 1–5)

| Level | Grid | Colors | Moves | Objective | New Mechanic | Notes |
|---|---|---|---|---|---|---|
| 1 | 7×7 | 3 | 40 | Collect 15 Ruby | Basic matching | Tutorial overlay explains swipe. |
| 2 | 7×7 | 3 | 35 | Collect 20 mixed | Matching | Tutorial: objectives panel. |
| 3 | 7×8 | 4 | 35 | Collect 10 Ruby + 10 Sapphire | 4th color introduced | Tutorial: multiple objectives. |
| 4 | 7×8 | 4 | 30 | Create 2 Rockets | Match-4 → Rocket | Tutorial: power-ups, how to match 4. |
| 5 | 7×9 | 4 | 30 | Create 1 Bomb, use it | Match-5 L/T → Bomb | Tutorial: L/T shapes, activation. |

### 3.2 Chapter 1: Grand Hall (Levels 6–30)

| Level | Grid | Colors | Moves | Objectives | Blockers | Special |
|---|---|---|---|---|---|---|
| 6 | 7×9 | 4 | 30 | Collect 30 Emerald | — | First non-tutorial level. |
| 7 | 7×9 | 4 | 28 | Collect 25 Ruby + 25 Sapphire | — | Two-color objective. |
| 8 | 7×9 | 4 | 28 | Create 3 Rockets | — | Power-up creation objective. |
| 9 | 7×9 | 4 | 25 | Remove 6 Crates | 6 Crates | **Crates introduced.** |
| 10 | 7×9 | 4 | 25 | Remove 10 Crates | 10 Crates (cluster) | Crate density up. First room complete → decoration unlock. |
| 11 | 7×9 | 4 | 25 | Collect 35 Topaz | 4 Crates (edges) | Crates as obstacles, not primary objective. |
| 12 | 7×9 | 4 | 24 | Remove 8 Crates + Collect 20 Ruby | 8 Crates | Mixed objective. |
| 13 | 7×9 | 4 | 24 | Create 1 Prism | — | **Prism introduced** (match-5 straight). |
| 14 | 7×9 | 4 | 24 | Use 1 Prism + Collect 30 gems | — | Prism usage practice. |
| 15 | 7×9 | 4 | 22 | Remove 8 Crates + Create 2 Rockets | 8 Crates | Combined mechanics. Room 3 starts. |
| 16 | 7×9 | 5 | 25 | Collect 20 Amethyst | — | **5th color (Amethyst) introduced.** |
| 17 | 7×9 | 5 | 24 | Collect 25 of any 2 colors | 4 Crates | 5-color board increases difficulty. |
| 18 | 7×9 | 5 | 24 | Remove 6 Ice(1-layer) | 6 Ice | **Ice introduced.** |
| 19 | 7×9 | 5 | 22 | Remove 8 Ice + Collect 20 Ruby | 8 Ice(1-layer) | Ice + color objective. |
| 20 | 7×9 | 5 | 22 | Remove 4 Ice(2-layer) + 6 Crates | 4 Ice(2), 6 Crate | **2-layer Ice introduced.** Room 4 starts. |
| 21 | 7×9 | 5 | 22 | Drop 3 Royal Eggs | 3 Eggs + 2 Nests | **Royal Eggs introduced.** |
| 22 | 7×9 | 5 | 22 | Drop 2 Eggs + Remove 6 Crates | 2 Eggs, 6 Crates | Eggs + blockers combo. |
| 23 | 7×9 | 5 | 20 | Spread coverage 60% | — | **Coverage objective introduced.** |
| 24 | 7×9 | 5 | 20 | Spread coverage 70% + Remove 4 Ice | 4 Ice(1) | Coverage + blockers. |
| 25 | Irregular | 5 | 22 | Remove 10 Crates + 4 Ice | 10 Crates, 4 Ice(2) | **Irregular board shape.** Room 5 (final room of Ch.1). |
| 26 | Irregular | 5 | 20 | Collect 40 gems of 2 colors | 6 Crates | Irregular board challenge. |
| 27 | 7×9 | 5 | 20 | Remove 6 Vases | 6 Vases(1hp) | **Vases introduced.** |
| 28 | 7×9 | 5 | 20 | Remove 4 Vases + Create 3 Bombs | 4 Vases(2hp), 4 Crates | 2-hp Vases. |
| 29 | 7×9 | 5 | 18 | Drop 4 Eggs + Remove 6 Ice | 4 Eggs, 6 Ice(2) | Multi-mechanic combination. |
| 30 | 8×10 | 5 | 25 | Remove ALL blockers (12) | 4 Crates, 4 Ice(2), 4 Vases(1) | **Chapter 1 Boss Level** — larger board, all Ch.1 blockers. |

### 3.3 Castle Tasks for Chapter 1

```
Room 1: Entrance Foyer (4 tasks, unlocked at Level 1)
  Task 1: "Sweep the dusty floor"      → 1 star → floor texture changes
  Task 2: "Replace the broken lantern"  → 1 star → lantern appears + glow
  Task 3: "Hang the welcome banner"     → 1 star → banner + bunting
  Task 4: "Open the grand doors"        → 1 star → doors animate open
  [Room complete: Percival dialogue, +1 Starting Rocket reward]

Room 2: Main Hall (5 tasks, unlocked at Level 6)
  Task 1: "Repair the cracked pillars"  → 1 star
  Task 2: "Roll out the red carpet"     → 1 star
  Task 3: "Light the wall sconces"      → 1 star
  Task 4: "Mount the royal crest"       → 1 star
  Task 5: "Polish the marble floor"     → 1 star
  [Room complete: Elara dialogue, +2 Hammers reward]

Room 3: Chandelier Gallery (5 tasks, unlocked at Level 11)
  ...similar pattern, 1 star each...
  [Room complete: Gideon dialogue, +1 Shuffle reward]

Room 4: Throne Room (6 tasks, unlocked at Level 16)
  ...6 tasks, 1 star each...
  [Room complete: Story cutscene, +1 Starting Bomb reward]

Room 5: Royal Portrait Wing (6 tasks, unlocked at Level 21)
  ...6 tasks, 1 star each...
  [Chapter complete: Major cutscene, full energy refill + Infinity Rush]
```

Total stars to 100% Chapter 1: 26 stars (26 tasks).
Maximum possible stars from levels 1–30: 90 (30 levels × 3 stars).
Minimum to pass gate at Level 50: 40 stars.
So a player earning ~1.5 stars average per level is comfortable.

---

## 4. Level Editor Tool (Internal)

### 4.1 Purpose

Designing hundreds of levels by hand-editing JSON is not sustainable. An
internal level editor accelerates content creation.

### 4.2 Features

- **Visual grid editor:** Click to place/remove cells, blockers, special tiles.
- **Objective builder:** GUI for adding/configuring objectives.
- **Play-test button:** Instantly play the level in-editor.
- **Auto-solver:** Run N simulations to estimate win rate and average moves.
- **Batch operations:** Adjust move limits across a range of levels.
- **Export:** Save as level JSON to the `data/levels/` directory.
- **Import:** Load existing levels for editing.

### 4.3 Implementation

Built as a Godot `@tool` script (editor plugin) so it runs inside the Godot
editor. Not shipped to players.

---

## 5. Automated Balance Solver

### 5.1 Purpose

Every level must be verified as fair before shipping. The solver plays each
level thousands of times using heuristic AI to estimate real-world win rates.

### 5.2 Solver Strategy

The solver uses a weighted random strategy that approximates an average player:

1. Scan all valid moves.
2. Score each move:
   - +10 if it creates a power-up (match 4+).
   - +5 if it progresses an objective (clears target color/blocker).
   - +3 if it creates a cascade (estimated by board pattern).
   - +1 base.
3. Pick a move with probability proportional to score (softmax selection).
4. Execute move, cascade, repeat.

This is intentionally weaker than optimal play to simulate a real player who
sometimes makes suboptimal moves.

### 5.3 Output

```
Level 15 — 10,000 simulations:
  Win rate:           91.2%  [TARGET: ≥ 85%]  ✅
  Avg moves remaining: 4.2
  Avg score:           8,450
  3-star rate:         22.1%
  2-star rate:         48.7%
  1-star rate:         20.4%
  Fail rate:            8.8%
  Avg boosters used:    0.0 (solver doesn't use boosters)
```

Levels failing the target win rate are flagged. Common fixes:
- Increase move limit by 1–3.
- Reduce blocker count.
- Reduce gem color count.
- Widen the board.

---

## 6. Progression Pacing Summary

| Milestone | Level | Stars Needed | Cumulative Max Stars | Player Effort |
|---|---|---|---|---|
| Ch.1 Room 1 complete | ~5 | 4 | 15 | Trivial |
| Ch.1 Room 2 complete | ~10 | 9 total | 30 | Easy |
| Ch.1 complete | ~30 | 26 total | 90 | Comfortable |
| Gate 1 | 50 | 40 | 150 | ~1.3 avg stars/level needed |
| Ch.2 complete | ~60 | 55 total | 180 | Comfortable |
| Gate 2 | 100 | 90 | 300 | ~1.5 avg needed (slight pressure to replay) |
| Expert mode unlock | ~75 (Ch.3 done) | N/A | N/A | Skill milestone |
| Gate 3 | 150 | 150 | 450 | ~1.5 avg (replaying for stars becomes optional strategy) |

The gates are deliberately lenient. A player who averages 1.5 stars per level
(well below the 3-star max) will never be blocked. Players who want to 3-star
everything will have a massive star surplus.

---

## 7. Quest & Event Schema

### 7.1 Daily Quest Format

```json
{
  "quest_id": "daily_win_3",
  "title": "Triple Victory",
  "description": "Win 3 levels today",
  "objective_type": "WIN_LEVELS",
  "target": 3,
  "reward": {
    "coins": 150,
    "boosters": { "hammer": 1 }
  },
  "reset": "DAILY"
}
```

### 7.2 Weekly Challenge Format

```json
{
  "event_id": "weekly_2026_w07",
  "title": "Rocket Week",
  "description": "Create as many Rockets as you can this week!",
  "duration_days": 7,
  "tiers": [
    { "target": 10, "reward": { "coins": 200 } },
    { "target": 25, "reward": { "boosters": { "starting_rocket": 2 } } },
    { "target": 50, "reward": { "coins": 500, "gem_skin": "neon_rockets" } }
  ]
}
```

### 7.3 Treasure Hunt Format

```json
{
  "event_id": "treasure_hunt_underwater",
  "title": "Underwater Ruins",
  "description": "Explore 10 sunken levels for hidden treasure!",
  "levels": [201, 202, 203, 204, 205, 206, 207, 208, 209, 210],
  "completion_reward": {
    "coins": 1000,
    "boosters": { "starting_prism": 1, "hammer": 3 },
    "cosmetic": "castle_theme_underwater"
  },
  "duration_days": 14
}
```

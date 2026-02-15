class_name GemTypes
## Enumerations and constants for the match-3 board system.

# --- Gem Colors ---
enum GemColor {
	NONE = -1,
	RUBY = 0,
	SAPPHIRE = 1,
	EMERALD = 2,
	TOPAZ = 3,
	AMETHYST = 4,
	DIAMOND = 5,
}

# --- Power-Up Types ---
enum PowerUpType {
	NONE = 0,
	ROCKET_H = 1,     # Horizontal rocket (clears row)
	ROCKET_V = 2,     # Vertical rocket (clears column)
	BOMB = 3,          # 3x3 area clear
	PRISM = 4,         # Color bomb (clears all of one color)
}

# --- Blocker Types ---
enum BlockerType {
	NONE = 0,
	CRATE = 1,              # 1-hit, destroyed by adjacent match
	REINFORCED_CRATE = 2,   # 2-3 hits
	ICE = 3,                # Freezes gem, 1-3 layers
	CHAIN = 4,              # Must match the chained gem itself
	VASE = 5,               # Occupies cell, adjacent match destroys
	STONE = 6,              # Indestructible, only power-ups remove
	ROYAL_EGG = 7,          # Must drop to nest
}

# --- Special Tile Types ---
enum SpecialTile {
	NONE = 0,
	PORTAL_IN = 1,
	PORTAL_OUT = 2,
	CONVEYOR_LEFT = 3,
	CONVEYOR_RIGHT = 4,
	CONVEYOR_UP = 5,
	CONVEYOR_DOWN = 6,
	NEST = 7,
	GENERATOR = 8,
}

# --- Objective Types ---
enum ObjectiveType {
	COLLECT_COLOR = 0,
	REMOVE_BLOCKER = 1,
	DROP_ITEM = 2,
	SPREAD_COVERAGE = 3,
	CREATE_POWERUP = 4,
	SCORE_TARGET = 5,
	COMBO_CHAIN = 6,
}

# --- Level Difficulty ---
enum Difficulty {
	TUTORIAL = 0,
	EASY = 1,
	MEDIUM = 2,
	HARD = 3,
	VERY_HARD = 4,
	EXPERT = 5,
}

# --- Color display names ---
static var COLOR_NAMES: Dictionary = {
	GemColor.RUBY: "Ruby",
	GemColor.SAPPHIRE: "Sapphire",
	GemColor.EMERALD: "Emerald",
	GemColor.TOPAZ: "Topaz",
	GemColor.AMETHYST: "Amethyst",
	GemColor.DIAMOND: "Diamond",
}

# --- Color hex values for rendering ---
static var COLOR_HEX: Dictionary = {
	GemColor.RUBY: Color("ff3b4a"),
	GemColor.SAPPHIRE: Color("4dabf7"),
	GemColor.EMERALD: Color("51cf66"),
	GemColor.TOPAZ: Color("ffd43b"),
	GemColor.AMETHYST: Color("cc5de8"),
	GemColor.DIAMOND: Color("a5d8ff"),
}

# --- Power-up display info ---
static var POWERUP_SYMBOLS: Dictionary = {
	PowerUpType.ROCKET_H: "→",
	PowerUpType.ROCKET_V: "↑",
	PowerUpType.BOMB: "✸",
	PowerUpType.PRISM: "◆",
}

# --- String-to-enum parsers (for JSON loading) ---
static func color_from_string(s: String) -> GemColor:
	match s.to_upper():
		"RUBY": return GemColor.RUBY
		"SAPPHIRE": return GemColor.SAPPHIRE
		"EMERALD": return GemColor.EMERALD
		"TOPAZ": return GemColor.TOPAZ
		"AMETHYST": return GemColor.AMETHYST
		"DIAMOND": return GemColor.DIAMOND
		_: return GemColor.NONE

static func blocker_from_string(s: String) -> BlockerType:
	match s.to_upper():
		"CRATE": return BlockerType.CRATE
		"REINFORCED_CRATE": return BlockerType.REINFORCED_CRATE
		"ICE": return BlockerType.ICE
		"CHAIN": return BlockerType.CHAIN
		"VASE": return BlockerType.VASE
		"STONE": return BlockerType.STONE
		"ROYAL_EGG": return BlockerType.ROYAL_EGG
		_: return BlockerType.NONE

static func objective_from_string(s: String) -> ObjectiveType:
	match s.to_upper():
		"COLLECT_COLOR": return ObjectiveType.COLLECT_COLOR
		"REMOVE_BLOCKER": return ObjectiveType.REMOVE_BLOCKER
		"DROP_ITEM": return ObjectiveType.DROP_ITEM
		"SPREAD_COVERAGE": return ObjectiveType.SPREAD_COVERAGE
		"CREATE_POWERUP": return ObjectiveType.CREATE_POWERUP
		"SCORE_TARGET": return ObjectiveType.SCORE_TARGET
		"COMBO_CHAIN": return ObjectiveType.COMBO_CHAIN
		_: return ObjectiveType.COLLECT_COLOR

static func difficulty_from_string(s: String) -> Difficulty:
	match s.to_upper():
		"TUTORIAL": return Difficulty.TUTORIAL
		"EASY": return Difficulty.EASY
		"MEDIUM": return Difficulty.MEDIUM
		"HARD": return Difficulty.HARD
		"VERY_HARD": return Difficulty.VERY_HARD
		"EXPERT": return Difficulty.EXPERT
		_: return Difficulty.EASY

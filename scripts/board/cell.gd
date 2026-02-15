class_name Cell
## Represents a single cell on the match-3 board.
## This is a pure data object with no rendering logic.

var gem_color: GemTypes.GemColor = GemTypes.GemColor.NONE
var power_up: GemTypes.PowerUpType = GemTypes.PowerUpType.NONE
var blocker_type: GemTypes.BlockerType = GemTypes.BlockerType.NONE
var blocker_hp: int = 0
var special_tile: GemTypes.SpecialTile = GemTypes.SpecialTile.NONE
var is_empty: bool = false       # true = hole in the board (no cell here)
var is_marked: bool = false      # flagged for removal this frame
var portal_link_id: int = -1     # for portal pairs
var row: int = 0
var col: int = 0


func _init(r: int = 0, c: int = 0) -> void:
	row = r
	col = c


func has_gem() -> bool:
	return gem_color != GemTypes.GemColor.NONE and not is_empty


func has_blocker() -> bool:
	return blocker_type != GemTypes.BlockerType.NONE


func has_power_up() -> bool:
	return power_up != GemTypes.PowerUpType.NONE


func is_swappable() -> bool:
	## A cell can be swapped if it has a gem and isn't frozen by certain blockers.
	if is_empty:
		return false
	if not has_gem():
		return false
	# Ice prevents swapping
	if blocker_type == GemTypes.BlockerType.ICE:
		return false
	return true


func is_matchable() -> bool:
	## Can this cell participate in a match?
	if is_empty or not has_gem():
		return false
	# Ice-covered gems can still be matched (match removes ice layer)
	# Chained gems can be matched (match removes chain)
	return true


func clear_gem() -> void:
	gem_color = GemTypes.GemColor.NONE
	power_up = GemTypes.PowerUpType.NONE
	is_marked = false


func set_gem(color: GemTypes.GemColor, pup: GemTypes.PowerUpType = GemTypes.PowerUpType.NONE) -> void:
	gem_color = color
	power_up = pup
	is_marked = false


func set_blocker(type: GemTypes.BlockerType, hp: int = 1) -> void:
	blocker_type = type
	blocker_hp = hp


func hit_blocker() -> bool:
	## Reduce blocker HP by 1. Returns true if blocker is destroyed.
	if blocker_type == GemTypes.BlockerType.NONE:
		return false
	if blocker_type == GemTypes.BlockerType.STONE:
		return false  # indestructible
	blocker_hp -= 1
	if blocker_hp <= 0:
		blocker_type = GemTypes.BlockerType.NONE
		blocker_hp = 0
		return true
	return false


func duplicate_cell() -> Cell:
	var c := Cell.new(row, col)
	c.gem_color = gem_color
	c.power_up = power_up
	c.blocker_type = blocker_type
	c.blocker_hp = blocker_hp
	c.special_tile = special_tile
	c.is_empty = is_empty
	c.is_marked = is_marked
	c.portal_link_id = portal_link_id
	return c


func _to_string() -> String:
	if is_empty:
		return "[  ]"
	if has_blocker() and not has_gem():
		return "[BLK]"
	var s: String = GemTypes.COLOR_NAMES.get(gem_color, "?") if has_gem() else "."
	if has_power_up():
		s += str(GemTypes.POWERUP_SYMBOLS.get(power_up, ""))
	return "[%s]" % s

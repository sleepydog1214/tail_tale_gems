extends Node
## Audio manager singleton (AutoLoad).
## Phase 1: Stub implementation. Sound/music playback will be added in Phase 3.

# Audio buses
const MASTER_BUS := "Master"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

# Volume settings (0.0 to 1.0)
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var master_volume: float = 1.0

# Mute state
var music_muted: bool = false
var sfx_muted: bool = false


func _ready() -> void:
	pass


# --- Music ---

func play_music(_track_name: String) -> void:
	## Play a music track by name. Stub for Phase 1.
	pass


func stop_music() -> void:
	## Stop current music. Stub for Phase 1.
	pass


func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)


# --- SFX ---

func play_sfx(_sfx_name: String) -> void:
	## Play a sound effect by name. Stub for Phase 1.
	pass


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)


# --- Master ---

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)

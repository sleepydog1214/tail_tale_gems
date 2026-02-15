extends Node
## Audio manager singleton (AutoLoad).
## Phase 3: Functional audio with procedural SFX tones and music stubs.
## Uses AudioStreamPlayer nodes and AudioServer bus management.

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

# Audio players
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8
var _current_music_track: String = ""

# SFX definitions: name -> {frequency, duration, type}
var _sfx_defs: Dictionary = {
	"gem_swap": {"freq": 440.0, "dur": 0.08, "type": "sine"},
	"gem_match": {"freq": 660.0, "dur": 0.12, "type": "sine"},
	"gem_land": {"freq": 220.0, "dur": 0.05, "type": "sine"},
	"cascade": {"freq": 880.0, "dur": 0.1, "type": "sine"},
	"powerup_create": {"freq": 1200.0, "dur": 0.2, "type": "sine"},
	"powerup_activate": {"freq": 500.0, "dur": 0.25, "type": "square"},
	"level_start": {"freq": 523.0, "dur": 0.15, "type": "sine"},
	"level_win": {"freq": 784.0, "dur": 0.3, "type": "sine"},
	"level_lose": {"freq": 196.0, "dur": 0.4, "type": "sine"},
	"button_click": {"freq": 600.0, "dur": 0.05, "type": "sine"},
	"booster_use": {"freq": 1000.0, "dur": 0.15, "type": "square"},
	"star_earn": {"freq": 1047.0, "dur": 0.2, "type": "sine"},
	"coin_earn": {"freq": 1320.0, "dur": 0.08, "type": "sine"},
	"hint_show": {"freq": 350.0, "dur": 0.12, "type": "sine"},
	"no_match": {"freq": 150.0, "dur": 0.15, "type": "square"},
	"select": {"freq": 500.0, "dur": 0.04, "type": "sine"},
	"daily_reward": {"freq": 880.0, "dur": 0.25, "type": "sine"},
}


func _ready() -> void:
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MASTER_BUS  # Use master since we don't have custom buses yet
	add_child(_music_player)

	# Create SFX player pool
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = MASTER_BUS
		add_child(player)
		_sfx_players.append(player)

	# Apply saved settings if SaveManager is available
	_load_settings.call_deferred()


func _load_settings() -> void:
	if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
		var settings: Dictionary = SaveManager.get_settings()
		set_music_volume(float(settings.get("music_volume", 0.8)))
		set_sfx_volume(float(settings.get("sfx_volume", 1.0)))
		set_master_volume(float(settings.get("master_volume", 1.0)))


# --- Music ---

func play_music(track_name: String) -> void:
	## Play a music track. Currently generates a simple ambient tone.
	if music_muted:
		return
	if track_name == _current_music_track and _music_player.playing:
		return
	_current_music_track = track_name
	# Phase 3: Placeholder — no actual music files yet
	# When music assets are added, load them here:
	# var stream = load("res://assets/audio/music/" + track_name + ".ogg")
	# _music_player.stream = stream
	# _music_player.play()


func stop_music() -> void:
	_music_player.stop()
	_current_music_track = ""


func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	if _music_player:
		_music_player.volume_db = linear_to_db(music_volume * master_volume)


func toggle_music_mute() -> void:
	music_muted = not music_muted
	if music_muted:
		_music_player.volume_db = -80.0
	else:
		_music_player.volume_db = linear_to_db(music_volume * master_volume)


# --- SFX ---

func play_sfx(sfx_name: String) -> void:
	## Play a sound effect by name using procedural audio.
	if sfx_muted:
		return

	var def: Dictionary = _sfx_defs.get(sfx_name, {})
	if def.is_empty():
		return

	var player := _get_free_sfx_player()
	if player == null:
		return

	var stream := _generate_tone(
		float(def.get("freq", 440.0)),
		float(def.get("dur", 0.1)),
		str(def.get("type", "sine"))
	)
	if stream:
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		player.play()


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)


func toggle_sfx_mute() -> void:
	sfx_muted = not sfx_muted


# --- Master ---

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	set_music_volume(music_volume)  # Re-apply


# --- Internal ---

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return _sfx_players[0]  # Steal oldest if all busy


func _generate_tone(freq: float, duration: float, wave_type: String = "sine") -> AudioStreamWAV:
	## Generate a short procedural tone.
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit samples = 2 bytes each

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var fade: float = 1.0 - (float(i) / float(num_samples))  # Linear fade out
		fade = fade * fade  # Quadratic fade for smoother decay
		var sample_val: float = 0.0

		match wave_type:
			"sine":
				sample_val = sin(t * freq * TAU) * fade
			"square":
				sample_val = (1.0 if sin(t * freq * TAU) > 0 else -1.0) * fade * 0.5

		var sample_int: int = clampi(int(sample_val * 16000.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	stream.stereo = false
	return stream

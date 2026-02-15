extends Node
## Manages save/load of player progress to local storage.
## Phase 3: Persistent player data with auto-save.

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

signal data_loaded
signal data_saved

var data: Dictionary = {}
var _dirty: bool = false


func _ready() -> void:
	load_data()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_data()


# ============================================================
# PUBLIC API
# ============================================================

func get_progress() -> Dictionary:
	return data.get("progress", {})


func get_level_stars(level_id: int) -> int:
	var levels: Dictionary = get_progress().get("levels", {})
	var entry: Dictionary = levels.get(str(level_id), {})
	return int(entry.get("stars", 0))


func set_level_stars(level_id: int, stars: int, score: int) -> void:
	_ensure_progress()
	var levels: Dictionary = data["progress"]["levels"]
	var key := str(level_id)
	var prev: Dictionary = levels.get(key, {})
	var prev_stars: int = int(prev.get("stars", 0))
	var attempts: int = int(prev.get("attempts", 0)) + 1

	if stars > prev_stars:
		levels[key] = {
			"stars": stars,
			"best_score": maxi(score, int(prev.get("best_score", 0))),
			"attempts": attempts,
		}
		_recalculate_total_stars()
	else:
		prev["attempts"] = attempts
		prev["best_score"] = maxi(score, int(prev.get("best_score", 0)))
		levels[key] = prev

	_mark_dirty()


func get_total_stars() -> int:
	return int(get_progress().get("total_stars", 0))


func get_coins() -> int:
	return int(get_progress().get("coins", 0))


func add_coins(amount: int) -> void:
	_ensure_progress()
	data["progress"]["coins"] = get_coins() + amount
	_mark_dirty()


func spend_coins(amount: int) -> bool:
	if get_coins() < amount:
		return false
	_ensure_progress()
	data["progress"]["coins"] = get_coins() - amount
	_mark_dirty()
	return true


func get_highest_level_unlocked() -> int:
	var levels: Dictionary = get_progress().get("levels", {})
	var highest: int = 0
	for key in levels:
		var lvl: int = int(key)
		if lvl > highest:
			highest = lvl
	return highest + 1  # Next level is unlocked


func get_max_level_available() -> int:
	return maxi(get_highest_level_unlocked(), 1)


# --- Energy ---

func get_energy() -> int:
	_ensure_progress()
	var stored: int = int(data["progress"].get("energy", 15))
	var last_regen: int = int(data["progress"].get("energy_regen_timestamp", 0))
	if last_regen == 0:
		return stored
	var now: int = int(Time.get_unix_time_from_system())
	var elapsed: int = now - last_regen
	var regen_ticks: int = elapsed / 600  # 1 energy per 10 minutes
	var current: int = mini(stored + regen_ticks, 15)
	return current


func consume_energy(amount: int = 1) -> bool:
	var current: int = get_energy()
	if current < amount:
		return false
	_ensure_progress()
	data["progress"]["energy"] = current - amount
	data["progress"]["energy_regen_timestamp"] = int(Time.get_unix_time_from_system())
	_mark_dirty()
	return true


func refund_energy(amount: int = 1) -> void:
	_ensure_progress()
	var current: int = get_energy()
	data["progress"]["energy"] = mini(current + amount, 15)
	data["progress"]["energy_regen_timestamp"] = int(Time.get_unix_time_from_system())
	_mark_dirty()


func refill_energy() -> void:
	_ensure_progress()
	data["progress"]["energy"] = 15
	data["progress"]["energy_regen_timestamp"] = int(Time.get_unix_time_from_system())
	_mark_dirty()


# --- Boosters ---

func get_booster_count(booster_type: String) -> int:
	var inv: Dictionary = data.get("inventory", {})
	return int(inv.get(booster_type, 0))


func add_booster(booster_type: String, amount: int = 1) -> void:
	_ensure_inventory()
	data["inventory"][booster_type] = get_booster_count(booster_type) + amount
	_mark_dirty()


func use_booster(booster_type: String) -> bool:
	if get_booster_count(booster_type) <= 0:
		return false
	_ensure_inventory()
	data["inventory"][booster_type] = get_booster_count(booster_type) - 1
	_mark_dirty()
	return true


# --- Daily Login ---

func get_daily_login() -> Dictionary:
	return data.get("daily", {})


func record_daily_login() -> Dictionary:
	## Returns the reward info for today's login, or empty if already claimed.
	_ensure_daily()
	var daily: Dictionary = data["daily"]
	var today: String = Time.get_date_string_from_system()
	var last_login: String = daily.get("last_login", "")

	if last_login == today:
		return {}  # Already claimed

	var streak: int = int(daily.get("login_streak", 0))

	# Check if streak continues (yesterday) or resets
	if last_login != "":
		var last_dict: Dictionary = Time.get_datetime_dict_from_datetime_string(last_login + "T00:00:00", false)
		var today_dict: Dictionary = Time.get_datetime_dict_from_datetime_string(today + "T00:00:00", false)
		var last_unix: int = int(Time.get_unix_time_from_datetime_dict(last_dict))
		var today_unix: int = int(Time.get_unix_time_from_datetime_dict(today_dict))
		var diff_days: int = (today_unix - last_unix) / 86400
		if diff_days == 1:
			streak += 1
		elif diff_days > 1:
			streak = 1
	else:
		streak = 1

	daily["login_streak"] = streak
	daily["last_login"] = today
	_mark_dirty()

	# Return rewards based on day-in-cycle (1-7)
	var day_in_cycle: int = ((streak - 1) % 7) + 1
	return _get_daily_reward(day_in_cycle, streak)


func _get_daily_reward(day_in_cycle: int, streak: int) -> Dictionary:
	var reward: Dictionary = {}
	match day_in_cycle:
		1:
			reward = {"type": "coins", "amount": 100, "label": "100 Coins"}
		2:
			reward = {"type": "booster", "booster": "hammer", "amount": 1, "label": "1 Royal Hammer"}
		3:
			reward = {"type": "coins", "amount": 200, "label": "200 Coins"}
		4:
			reward = {"type": "booster", "booster": "starting_rocket", "amount": 1, "label": "1 Starting Rocket"}
		5:
			reward = {"type": "energy", "amount": 5, "label": "+5 Energy"}
		6:
			reward = {"type": "booster", "booster": "shuffle", "amount": 1, "label": "1 Shuffle"}
		7:
			reward = {"type": "coins", "amount": 500, "label": "500 Coins + 1 Prism"}
			# Day 7 also gives a Prism
			add_booster("starting_prism", 1)
			if streak >= 14:
				reward["amount"] = 1000
				reward["label"] = "1000 Coins + 1 Prism (Streak Bonus!)"

	# Apply the reward
	match reward.get("type", ""):
		"coins":
			add_coins(int(reward["amount"]))
		"booster":
			add_booster(str(reward["booster"]), int(reward["amount"]))
		"energy":
			_ensure_progress()
			data["progress"]["energy"] = mini(get_energy() + int(reward["amount"]), 20)

	reward["day"] = day_in_cycle
	reward["streak"] = streak
	return reward


# --- Settings ---

func get_settings() -> Dictionary:
	return data.get("settings", _default_settings())


func set_setting(key: String, value: Variant) -> void:
	if not data.has("settings"):
		data["settings"] = _default_settings()
	data["settings"][key] = value
	_mark_dirty()


func _default_settings() -> Dictionary:
	return {
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"master_volume": 1.0,
		"colorblind_mode": false,
		"reduced_motion": false,
	}


# --- Stats ---

func increment_stat(stat_name: String, amount: int = 1) -> void:
	if not data.has("stats"):
		data["stats"] = {}
	var current: int = int(data["stats"].get(stat_name, 0))
	data["stats"][stat_name] = current + amount
	_mark_dirty()


func get_stat(stat_name: String) -> int:
	return int(data.get("stats", {}).get(stat_name, 0))


# ============================================================
# PERSISTENCE
# ============================================================

func save_data() -> void:
	data["version"] = SAVE_VERSION
	data["last_saved_at"] = Time.get_datetime_string_from_system()
	var json_text := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing")
		return
	file.store_string(json_text)
	file.close()
	_dirty = false
	data_saved.emit()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = _create_default_data()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading")
		data = _create_default_data()
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_text) != OK:
		push_error("SaveManager: JSON parse error: %s" % json.get_error_message())
		data = _create_default_data()
		return

	data = json.data
	data_loaded.emit()


func _create_default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"created_at": Time.get_datetime_string_from_system(),
		"progress": {
			"current_level": 1,
			"levels": {},
			"total_stars": 0,
			"coins": 0,
			"energy": 15,
			"energy_regen_timestamp": int(Time.get_unix_time_from_system()),
		},
		"inventory": {},
		"daily": {
			"login_streak": 0,
			"last_login": "",
		},
		"settings": _default_settings(),
		"stats": {},
	}


# ============================================================
# INTERNALS
# ============================================================

func _ensure_progress() -> void:
	if not data.has("progress"):
		data["progress"] = {
			"current_level": 1,
			"levels": {},
			"total_stars": 0,
			"coins": 0,
			"energy": 15,
			"energy_regen_timestamp": int(Time.get_unix_time_from_system()),
		}
	if not data["progress"].has("levels"):
		data["progress"]["levels"] = {}


func _ensure_inventory() -> void:
	if not data.has("inventory"):
		data["inventory"] = {}


func _ensure_daily() -> void:
	if not data.has("daily"):
		data["daily"] = {"login_streak": 0, "last_login": ""}


func _recalculate_total_stars() -> void:
	var total: int = 0
	var levels: Dictionary = data.get("progress", {}).get("levels", {})
	for key in levels:
		total += int(levels[key].get("stars", 0))
	data["progress"]["total_stars"] = total


func _mark_dirty() -> void:
	_dirty = true
	# Auto-save on every mutation for safety
	save_data()

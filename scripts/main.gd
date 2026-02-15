extends Node
## Main scene — entry point. Launches the main menu on startup.


func _ready() -> void:
	# Defer to next frame so the scene tree is fully initialized
	GameManager.go_to_main_menu.call_deferred()

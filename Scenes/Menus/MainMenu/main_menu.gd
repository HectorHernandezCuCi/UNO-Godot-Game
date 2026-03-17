extends Control
class_name MainMenu

func _ready() -> void:
	get_tree().paused = false

func _on_start_game_pressed() -> void:
	SceneManager.go_to_game()


func _on_exit_pressed() -> void:
	get_tree().quit()

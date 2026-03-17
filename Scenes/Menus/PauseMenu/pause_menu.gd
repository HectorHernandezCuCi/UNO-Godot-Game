extends Control
class_name PauseMenu

signal resumed

func _on_resume_pressed() -> void:
	SceneManager.pause_game(false)
	resumed.emit()


func _on_exit_game_pressed() -> void:
	SceneManager.go_to_main_menu()

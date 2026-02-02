extends Control
class_name PauseMenu


func _on_resume_pressed() -> void:
	self.visible = false
	SceneManager.pause_game(false)


func _on_exit_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/MainMenu.tscn")

extends Control
class_name MainMenu

func _ready() -> void:
	get_tree().paused = true

func _on_start_game_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/CardTest.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
	print("Press Quit")

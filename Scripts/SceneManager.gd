extends Node

func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menus/MainMenu/MainMenu.tscn")

func go_to_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Game/GameScreen.tscn")

func pause_game(paused: bool) -> void:
	get_tree().paused = paused

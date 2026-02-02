extends Node

func pause_game(pause: bool):
	get_tree().paused = pause
	
	var canvas := get_tree().current_scene.get_node("CanvasLayer")
	var pause_menu := canvas.get_node("PauseMenu")

	pause_menu.visible = pause

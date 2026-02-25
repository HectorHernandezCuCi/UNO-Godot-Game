extends Control

signal restart_pressed

@export var fade_time: float = 0.5

@onready var game_over_screen_background = $GameOverScreenBackground
@onready var player_wins_text = $PlayerWins
@onready var winning_player_label = $PlayerWins/Player
@onready var buttons = $Buttons

func change_winning_player(winning_player: String, transition_time: float = fade_time) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(winning_player_label, "text", winning_player, transition_time)

func _on_visibility_changed() -> void:
	var tween = create_tween().set_parallel()
	if visible:
		MusicManager.set_reverb_wet(1.0, 0.0, 1.0)
		MusicManager.set_lowpass_freq(2000, 1.0)
		tween.tween_property(game_over_screen_background, "modulate", Color("ffffffff"), fade_time)
		tween.tween_property(player_wins_text, "modulate", Color("ffffffff"), fade_time)
		tween.tween_property(buttons, "modulate", Color("ffffffff"), fade_time)
	else:
		MusicManager.set_reverb_wet(0.0, 1.0, 1.0)
		MusicManager.set_lowpass_freq(20000, 1.0)
		tween.tween_property(game_over_screen_background, "modulate", Color("ffffff00"), fade_time)
		tween.tween_property(player_wins_text, "modulate", Color("ffffff00"), fade_time)
		tween.tween_property(buttons, "modulate", Color("ffffff00"), fade_time)

func _on_restart_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		restart_pressed.emit()

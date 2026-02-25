extends Control

signal take_card_button_clicked

@onready var path_follower = $TurnIndicatorPath/PathFollow2D
@onready var pointer = $TurnIndicatorPath/PathFollow2D/Pointer
@onready var take_card_button = $TakeCardButton
@onready var take_card_label = $TakeCardButton/TakeCardLabel

func change_pointer_color(target_color: Color, transition_time: float = 0) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(pointer, "color", target_color, transition_time)

func change_pointer_position(target_progress_ratio: float, transition_time: float = 0) -> void:
	var tween = create_tween().set_parallel()
	var current_progress_ratio = path_follower.progress_ratio
	if transition_time == 0:
		path_follower.progress_ratio = target_progress_ratio
	else:
		if GameMaster.clockwise:
			if target_progress_ratio < current_progress_ratio:
				tween.tween_property(path_follower, "progress_ratio", 1, transition_time)
				tween.chain().tween_property(path_follower, "progress_ratio", 0, 0)
				tween.chain().tween_property(path_follower, "progress_ratio", target_progress_ratio, transition_time)
			else:
				tween.tween_property(path_follower, "progress_ratio", target_progress_ratio, transition_time).set_ease(Tween.EASE_OUT_IN)
		elif not GameMaster.clockwise:
			if target_progress_ratio > current_progress_ratio:
				tween.tween_property(path_follower, "progress_ratio", 0, transition_time)
				tween.chain().tween_property(path_follower, "progress_ratio", 1, 0)
				tween.chain().tween_property(path_follower, "progress_ratio", target_progress_ratio, transition_time)
			else:
				tween.tween_property(path_follower, "progress_ratio", target_progress_ratio, transition_time)

func change_take_card_button_color(target_color: Color, transition_time: float = 0.0) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(take_card_button, "material:shader_parameter/color_over", target_color, transition_time)

func _on_take_card_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if GameMaster.current_player == 0:
			if GameMaster.cards_to_be_taken > 0:
				GameMaster.draw_to_player_hand(GameMaster.cards_to_be_taken)
				GameMaster.cards_to_be_taken = 0
				change_take_card_button_number(1, 0.5)
				take_card_button_clicked.emit()
			else:
				GameMaster.draw_to_player_hand(1)
				take_card_button_clicked.emit()

func change_take_card_button_number(target_number: int = 1, transition_time: float = 0.0) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(take_card_label, "text", "Take Cards (+" + str(target_number) + ")", transition_time)

extends Control

signal color_selected

@onready var color_selector_background = $ColorSelectorBackground
@onready var color_selector_panel = $ColorSelectorPanel
@onready var color_selector_panel_background = $ColorSelectorPanel/PanelBackground

@export var background_color_transition_time: float = 1.0 

var default_panel_color = Color(1, 1, 1)

#blue button mouse enter and exit
func _on_button_blue_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(color_selector_panel_background, "material:shader_parameter/color_over", GameMaster.color_map["Blue"], background_color_transition_time)

func _on_button_blue_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(color_selector_panel_background, "material:shader_parameter/color_over", default_panel_color, background_color_transition_time)

#green button mouse enter and exit
func _on_button_green_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(color_selector_panel_background, "material:shader_parameter/color_over", GameMaster.color_map["Green"], background_color_transition_time)

func _on_button_green_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(color_selector_panel_background, "material:shader_parameter/color_over", default_panel_color, background_color_transition_time)

#red button mouse enter and exit
func _on_button_red_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(color_selector_panel_background, "material:shader_parameter/color_over", GameMaster.color_map["Red"], background_color_transition_time)

func _on_button_red_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(color_selector_panel_background, "material:shader_parameter/color_over", default_panel_color, background_color_transition_time)

#yellow button mouse enter and exit
func _on_button_yellow_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(color_selector_panel_background, "material:shader_parameter/color_over", GameMaster.color_map["Yellow"], background_color_transition_time)

func _on_button_yellow_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(color_selector_panel_background, "material:shader_parameter/color_over", default_panel_color, background_color_transition_time)


#blue button click
func _on_button_blue_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		GameMaster.current_color = "Blue"
		color_selected.emit()
		hide()

#green button click
func _on_button_green_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		GameMaster.current_color = "Green"
		color_selected.emit()
		hide()

#red button click
func _on_button_red_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		GameMaster.current_color = "Red"
		color_selected.emit()
		hide()

#yellow button click
func _on_button_yellow_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		GameMaster.current_color = "Yellow"
		color_selected.emit()
		hide()

func _on_visibility_changed() -> void:
	var tween = create_tween().set_parallel()
	if visible:
		MusicManager.set_reverb_wet(1.0, 0.0, 1.0)
		MusicManager.set_lowpass_freq(2000, 1.0)
		tween.tween_property(color_selector_background, "modulate", Color("ffffffff"), background_color_transition_time)
		tween.tween_property(color_selector_panel, "modulate", Color("ffffffff"), background_color_transition_time)
	else:
		MusicManager.set_reverb_wet(0.0, 1.0, 1.0)
		MusicManager.set_lowpass_freq(20000, 1.0)
		tween.tween_property(color_selector_background, "modulate", Color("ffffff00"), background_color_transition_time)
		tween.tween_property(color_selector_panel, "modulate", Color("ffffff00"), background_color_transition_time)

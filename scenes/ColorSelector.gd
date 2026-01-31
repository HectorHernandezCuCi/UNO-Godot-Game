extends CanvasLayer

signal color_selected(color_index)

@onready var panel = $PanelContainer
@onready var red_btn = $PanelContainer/VBoxContainer/HBoxContainer/Red
@onready var blue_btn = $PanelContainer/VBoxContainer/HBoxContainer/Blue
@onready var green_btn = $PanelContainer/VBoxContainer/HBoxContainer/Green
@onready var yellow_btn = $PanelContainer/VBoxContainer/HBoxContainer/Yellow
@onready var title_label = $PanelContainer/VBoxContainer/TitleLabel

# Colores para los botones
const COLORS = {
	"red": Color(0.9, 0.2, 0.2),
	"blue": Color(0.2, 0.5, 0.9),
	"green": Color(0.2, 0.8, 0.3),
	"yellow": Color(0.95, 0.85, 0.2)
}

func _ready():
	if panel == null:
		push_error("CRITICAL: 'PanelContainer' node not found!")
		return
	
	# Esperar un frame para asegurar que el UI esté listo
	await get_tree().process_frame
	
	# Setup del panel
	panel.pivot_offset = panel.size / 2
	
	# Estilizar los botones
	_style_buttons()
	
	# Conectar señales
	red_btn.pressed.connect(func(): _on_color_picked(0))
	blue_btn.pressed.connect(func(): _on_color_picked(1))
	green_btn.pressed.connect(func(): _on_color_picked(2))
	yellow_btn.pressed.connect(func(): _on_color_picked(3))
	
	# Conectar efectos hover
	_setup_hover_effects(red_btn, COLORS.red)
	_setup_hover_effects(blue_btn, COLORS.blue)
	_setup_hover_effects(green_btn, COLORS.green)
	_setup_hover_effects(yellow_btn, COLORS.yellow)
	
	# Animación de entrada profesional
	_play_entrance_animation()

func _style_buttons():
	"""Aplica estilos a los botones"""
	_apply_button_style(red_btn, COLORS.red)
	_apply_button_style(blue_btn, COLORS.blue)
	_apply_button_style(green_btn, COLORS.green)
	_apply_button_style(yellow_btn, COLORS.yellow)

func _apply_button_style(button: Button, color: Color):
	"""Aplica un estilo personalizado a un botón"""
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.corner_radius_top_left = 15
	style_normal.corner_radius_top_right = 15
	style_normal.corner_radius_bottom_left = 15
	style_normal.corner_radius_bottom_right = 15
	style_normal.shadow_size = 5
	style_normal.shadow_color = Color(0, 0, 0, 0.3)
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = color.lightened(0.2)
	style_hover.shadow_size = 8
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = color.darkened(0.2)
	style_pressed.shadow_size = 2
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	# Tamaño mínimo
	button.custom_minimum_size = Vector2(120, 120)

func _setup_hover_effects(button: Button, color: Color):
	"""Configura efectos de hover para los botones"""
	button.mouse_entered.connect(func():
		var tween = create_tween().set_parallel(true)
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "rotation", 0.05, 0.2)
	)
	
	button.mouse_exited.connect(func():
		var tween = create_tween().set_parallel(true)
		tween.tween_property(button, "scale", Vector2.ONE, 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "rotation", 0.0, 0.2)
	)

func _play_entrance_animation():
	"""Animación de entrada dramática"""
	# Fondo oscuro con fade-in - aplicado al panel en lugar del CanvasLayer
	panel.modulate = Color(1, 1, 1, 0)
	var fade_tween = create_tween()
	fade_tween.tween_property(panel, "modulate", Color.WHITE, 0.3)
	
	# Panel con efecto de rebote
	panel.scale = Vector2.ZERO
	panel.rotation = -0.3
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "rotation", 0.0, 0.4)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Animar botones secuencialmente
	await tween.finished
	_animate_buttons_in()

func _animate_buttons_in():
	"""Anima la entrada de cada botón con un pequeño retraso"""
	var buttons = [red_btn, blue_btn, green_btn, yellow_btn]
	var delay = 0.0
	
	for btn in buttons:
		btn.scale = Vector2.ZERO
		btn.modulate.a = 0
		
		await get_tree().create_timer(delay).timeout
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "modulate:a", 1.0, 0.2)
		
		delay += 0.08

func _on_color_picked(index: int):
	"""Maneja la selección de color con animación de salida"""
	color_selected.emit(index)
	
	# Efecto de pulso en el botón seleccionado
	var buttons = [red_btn, blue_btn, green_btn, yellow_btn]
	var selected_btn = buttons[index]
	
	var pulse = create_tween()
	pulse.tween_property(selected_btn, "scale", Vector2(1.3, 1.3), 0.1)
	pulse.tween_property(selected_btn, "scale", Vector2.ONE, 0.1)
	
	await pulse.finished
	
	# Animación de salida profesional
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ZERO, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "rotation", 0.5, 0.3)
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	queue_free()

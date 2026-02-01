extends CanvasLayer

signal uno_button_pressed

@onready var uno_button = $UnoButton
@onready var animation_player = $AnimationPlayer

var is_button_active: bool = false

func _ready():
	# Centramos el pivote para que la animación de escala sea desde el centro
	if uno_button:
		uno_button.pivot_offset = uno_button.size / 2
		uno_button.pressed.connect(_on_uno_button_pressed)
	
	# Empezamos ocultos
	hide_button()

func show_button():
	"""Muestra el botón y activa la animación de pulso"""
	if uno_button:
		uno_button.show()
		is_button_active = true
		if animation_player and animation_player.has_animation("pulse"):
			animation_player.play("pulse")

func hide_button():
	"""Oculta el botón y detiene animaciones"""
	if uno_button:
		uno_button.hide()
		is_button_active = false
		if animation_player:
			animation_player.stop()

func _on_uno_button_pressed():
	uno_button_pressed.emit()
	
	# Efecto visual de 'Pop' al hacer clic
	var tween = create_tween()
	tween.tween_property(uno_button, "scale", Vector2(1.2, 1.2), 0.05)
	tween.tween_property(uno_button, "scale", Vector2.ONE, 0.05)

extends CanvasLayer

@onready var label = $Label
@onready var animation_player = $AnimationPlayer
@onready var particles = $Particles  # Opcional: agrega partículas
@onready var glow = $Glow  # Opcional: efecto de resplandor
@onready var uno_sound_player: AudioStreamPlayer2D = $UnoSoundPlayer
@onready var uno_sound_ai: AudioStreamPlayer2D = $UnoSoundAI


# Colores para diferentes estados
const COLOR_UNO = Color(1.0, 0.85, 0.0)  # Dorado
const COLOR_PENALTY = Color(1.0, 0.2, 0.2)  # Rojo
const COLOR_AI = Color(0.3, 0.7, 1.0)  # Azul

func _ready():
	if label:
		label.visible = false
		label.modulate = Color.WHITE
		
func _play_uno_sound(player: AudioStreamPlayer2D):
	if not player:
		return
	
	if player.playing:
		player.stop()
	player.play()

func show_uno_announcement(player_name: String = "TÚ"):
	if label:
		_play_uno_sound(uno_sound_player)

		label.text = "¡%s DIJISTE UNO!" % player_name
		label.modulate = COLOR_UNO
		label.visible = true
		
		if animation_player and animation_player.has_animation("announce"):
			animation_player.play("announce")
		else:
			_play_professional_animation(COLOR_UNO, 3.5)



func show_ai_uno():
	if label:
		label.text = "¡LA IA DIJO UNO!"
		label.modulate = COLOR_AI
		label.visible = true
		
		if uno_sound_ai:
			uno_sound_ai.play()

		if animation_player and animation_player.has_animation("announce"):
			animation_player.play("announce")
		else:
			_play_professional_animation(COLOR_AI, 3.5)


func show_penalty_message():
	"""Shows penalty message when player forgot to say UNO"""
	if label:
		label.text = "¡OLVIDASTE DECIR UNO!\n+2 CARTAS"
		label.modulate = COLOR_PENALTY
		label.visible = true
		
		_play_penalty_animation()

func _play_professional_animation(color: Color, duration: float = 3.5):
	"""Professional animation with multiple effects"""
	var tween = create_tween()
	
	# Setup inicial
	label.modulate = color
	label.modulate.a = 0
	label.scale = Vector2(0.3, 0.3)
	label.rotation = -0.2
	
	# Fase 1: Entrada explosiva (0.5s)
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_property(label, "scale", Vector2(1.8, 1.8), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "rotation", 0.1, 0.3)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Fase 2: Bounce hacia tamaño normal (0.3s)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "rotation", 0.0, 0.2)
	
	# Fase 3: Pulso sutil mientras está visible (2s)
	tween.chain()
	var pulse_count = 4
	for i in pulse_count:
		tween.set_parallel(true)
		tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.25)\
			.set_trans(Tween.TRANS_SINE)
		tween.chain()
		tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.25)\
			.set_trans(Tween.TRANS_SINE)
		if i < pulse_count - 1:
			tween.chain()
	
	# Fase 4: Salida elegante (0.7s)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_property(label, "rotation", 0.15, 0.4)
	
	# Limpieza
	tween.chain()
	tween.tween_callback(_reset_label)
	
	# Efecto de brillo adicional
	_add_glow_effect(color, duration)

func _play_penalty_animation():
	"""Shake animation for penalty with urgency"""
	var tween = create_tween()
	
	# Setup
	label.modulate.a = 0
	label.scale = Vector2.ONE
	label.rotation = 0
	
	# Aparición rápida
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	
	# Shake violento (0.6s)
	tween.chain()
	var shake_intensity = 0.08
	var shake_duration = 0.05
	for i in 12:
		var random_rot = randf_range(-shake_intensity, shake_intensity)
		tween.tween_property(label, "rotation", random_rot, shake_duration)
	
	# Volver a centro
	tween.chain()
	tween.tween_property(label, "rotation", 0.0, 0.1)
	
	# Pulso de advertencia (1s)
	tween.chain()
	for i in 3:
		tween.set_parallel(true)
		tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.15)
		tween.tween_property(label, "modulate", COLOR_PENALTY * 1.3, 0.15)
		tween.chain()
		tween.set_parallel(true)
		tween.tween_property(label, "scale", Vector2.ONE, 0.15)
		tween.tween_property(label, "modulate", COLOR_PENALTY, 0.15)
		if i < 2:
			tween.chain()
	
	# Salida (0.8s)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.4)
	tween.tween_property(label, "scale", Vector2(0.8, 0.8), 0.6).set_delay(0.4)
	
	tween.chain()
	tween.tween_callback(_reset_label)

func _add_glow_effect(color: Color, duration: float):
	"""Adds a subtle glow pulse effect"""
	if not glow:
		return
	
	var tween = create_tween()
	glow.modulate = color
	glow.modulate.a = 0
	glow.visible = true
	
	# Fade in glow
	tween.tween_property(glow, "modulate:a", 0.6, 0.3)
	
	# Pulse durante la duración
	tween.chain()
	var pulse_time = duration - 1.0
	var pulses = int(pulse_time / 0.5)
	for i in pulses:
		tween.tween_property(glow, "modulate:a", 0.3, 0.25)
		tween.tween_property(glow, "modulate:a", 0.6, 0.25)
	
	# Fade out
	tween.chain()
	tween.tween_property(glow, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): glow.visible = false)

func _reset_label():
	"""Reset label to default state"""
	label.visible = false
	label.scale = Vector2.ONE
	label.rotation = 0
	label.modulate = Color.WHITE

extends Node2D

signal card_played(card_color: String, card_value: String)
# FIX: esta señal existía en _play_card_multiplayer() pero nunca se declaró
# ni se conectó en ningún lado → las Wild cards en multijugador no funcionaban.
signal color_pick_needed(card_color: String, card_value: String)

@export var scaling_amount  = 1.2
@export var angle_x_max: float
@export var angle_y_max: float

@onready var scale_animate           = $AnimationPlayer
@onready var scale_up_animation: Animation   = scale_animate.get_animation("ScaleUp")
@onready var scale_down_animation: Animation = scale_animate.get_animation("ScaleDown")
@onready var card_flick_sfx = $CardFlickSfx
@onready var card_play_sfx  = $CardPlaySfx

var default_z_index: int
var default_scale: Vector2
var hovering = false

func _ready() -> void:
	var game_screen = get_tree().root.get_node("GameScreen")
	card_played.connect(game_screen._on_card_played)
	# FIX: conectar color_pick_needed al GameScreen para que muestre el ColorSelector
	color_pick_needed.connect(game_screen._on_card_color_pick_needed)

	default_z_index = z_index
	default_scale   = scale

	if get_meta("CardBack"):
		get_node("CardFace").visible = false
		get_node("CardBack").visible = true
	else:
		get_node("CardFace").visible = true
		get_node("CardBack").visible = false

	name = get_meta("Color") + get_meta("Value")
	scale_up_animation.track_set_key_value(0, 0, default_scale)
	scale_up_animation.track_set_key_value(0, 1, scale * scaling_amount)
	scale_down_animation.track_set_key_value(0, 0, scale)
	scale_down_animation.track_set_key_value(0, 1, default_scale)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if hovering and event.pressed:
				if can_be_played():
					if GameMaster.is_multiplayer:
						_play_card_multiplayer()
					else:
						play_card(0)

	if hovering and get_meta("HoverEffect"):
		var mouse_pos   = get_local_mouse_position()
		var lerp_val_x  = remap(-mouse_pos.y, 0.0, $CardFace.size.x / 2, 0, 1)
		var lerp_val_y  = remap(-mouse_pos.x, 0.0, $CardFace.size.y / 2, 0, 1)
		var rot_x = rad_to_deg(lerp_angle(-angle_x_max,  angle_x_max, lerp_val_x))
		var rot_y = rad_to_deg(lerp_angle( angle_y_max, -angle_y_max, lerp_val_y))
		$CardFace.material.set_shader_parameter("x_rot", rot_x)
		$CardFace.material.set_shader_parameter("y_rot", rot_y)
		$CardBack.material.set_shader_parameter("x_rot", rot_x)
		$CardBack.material.set_shader_parameter("y_rot", rot_y)

func _on_control_mouse_entered() -> void:
	hovering = true
	if get_meta("HoverEffect"):
		set_atop()
		scale_animate.play("ScaleUp")
		card_flick_sfx.play()

func _on_control_mouse_exited() -> void:
	hovering = false
	z_index   = default_z_index
	scale_down_animation.track_set_key_value(0, 0, scale)
	scale_animate.play("ScaleDown")
	$CardFace.material.set_shader_parameter("x_rot", 0)
	$CardFace.material.set_shader_parameter("y_rot", 0)
	$CardBack.material.set_shader_parameter("x_rot", 0)
	$CardBack.material.set_shader_parameter("y_rot", 0)

func set_atop() -> void:
	var highest_z_index = 0
	for card in get_tree().get_nodes_in_group("Cards"):
		if card.z_index > highest_z_index:
			highest_z_index = card.z_index
	z_index = highest_z_index + 1

func play_card(played_from: int, selected_card: Node2D = self) -> void:
	match played_from:
		0:
			var idx  = GameMaster.player_hand.find(selected_card)
			var card = GameMaster.player_hand[idx]
			GameMaster.play_to_discard(0, card)
			card_play_sfx.play()
			emit_signal("card_played", card.get_meta("Color"), card.get_meta("Value"))
		1:
			var idx  = GameMaster.cpu1_hand.find(selected_card)
			var card = GameMaster.cpu1_hand[idx]
			GameMaster.play_to_discard(1, card)
			card_play_sfx.play()
			emit_signal("card_played", card.get_meta("Color"), card.get_meta("Value"))
		2:
			var idx  = GameMaster.cpu2_hand.find(selected_card)
			var card = GameMaster.cpu2_hand[idx]
			GameMaster.play_to_discard(2, card)
			card_play_sfx.play()
			emit_signal("card_played", card.get_meta("Color"), card.get_meta("Value"))
		3:
			var idx  = GameMaster.cpu3_hand.find(selected_card)
			var card = GameMaster.cpu3_hand[idx]
			GameMaster.play_to_discard(3, card)
			card_play_sfx.play()
			emit_signal("card_played", card.get_meta("Color"), card.get_meta("Value"))

func can_be_played(card: Node2D = self, cpu_hand: bool = false, picker: bool = false) -> bool:
	# Bloquear si no es el turno del jugador local
	if GameMaster.is_multiplayer and not cpu_hand:
		if not GameMaster._is_my_turn():
			return false

	var played_card_color = card.get_meta("Color")
	var played_card_value = card.get_meta("Value")

	if cpu_hand:
		if picker:
			return played_card_value == "Picker" or played_card_value == "PickFour" and \
				   played_card_value == GameMaster.get_top_discard_card().get_meta("Value")
		else:
			if played_card_color == "Wild":
				return true
			elif played_card_color == GameMaster.current_color:
				return true
			elif played_card_value == GameMaster.get_top_discard_card().get_meta("Value"):
				return true
			return false
	else:
		if picker:
			if played_card_value == "Picker" or played_card_value == "PickFour":
				return played_card_value == GameMaster.get_top_discard_card().get_meta("Value")
			return false
		else:
			if not card.get_meta("CanBePlayed"):
				return false
			if played_card_color == "Wild":
				return true
			elif played_card_color == GameMaster.current_color:
				return true
			elif played_card_value == GameMaster.get_top_discard_card().get_meta("Value"):
				return true
			return false

func set_card_back(card_back: bool) -> void:
	set_meta("CardBack", card_back)
	get_node("CardFace").visible = not card_back
	get_node("CardBack").visible = card_back

# Solicita jugar al host por red
func _play_card_multiplayer() -> void:
	var color = get_meta("Color")
	var value = get_meta("Value")
	# FIX: emitir la señal declarada correctamente para que GameScreen
	# muestre el ColorSelector y luego envíe la jugada al host con el color elegido.
	if color == "Wild":
		emit_signal("color_pick_needed", color, value)
	else:
		GameMaster.mp_play_card(color, value)

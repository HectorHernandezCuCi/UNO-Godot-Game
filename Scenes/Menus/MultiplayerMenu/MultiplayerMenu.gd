# Scenes/Menus/Multiplayer/MultiplayerMenu.gd
extends Control

@onready var name_input   = $CenterContainer/MainVBox/NamePanel/NameVBox/NameInput
@onready var code_input   = $CenterContainer/MainVBox/CardsHBox/JoinCard/JoinVBox/IpInput
@onready var status_label = $CenterContainer/MainVBox/StatusLabel
@onready var create_btn   = $CenterContainer/MainVBox/CardsHBox/CreateCard/CreateVBox/CreateButton
@onready var join_btn     = $CenterContainer/MainVBox/CardsHBox/JoinCard/JoinVBox/JoinButton
@onready var back_btn     = $CenterContainer/MainVBox/BackButton
@onready var main_vbox    = $CenterContainer/MainVBox

# StyleBoxes para feedback visual del input de nombre
@onready var name_input_node = $CenterContainer/MainVBox/NamePanel/NameVBox/NameInput

var _sf_input_normal: StyleBoxFlat
var _sf_input_error: StyleBoxFlat
var _sf_input_ok: StyleBoxFlat

func _ready() -> void:
	NetworkManager.server_created.connect(_on_server_created)
	NetworkManager.joined_server.connect(_on_joined_server)
	NetworkManager.connection_failed.connect(_on_connection_failed)

	if not NetworkManager.local_username.is_empty():
		name_input.text = NetworkManager.local_username

	# Preparar styleboxes de feedback para el input de nombre
	_sf_input_normal = name_input.get_theme_stylebox("normal").duplicate()
	_sf_input_error  = _sf_input_normal.duplicate()
	_sf_input_error.border_color = Color(0.85, 0.12, 0.16, 1)
	_sf_input_ok     = _sf_input_normal.duplicate()
	_sf_input_ok.border_color    = Color(0.10, 0.75, 0.28, 1)

	name_input.text_changed.connect(_on_name_changed)

	# Animación de entrada
	main_vbox.modulate.a = 0.0
	main_vbox.position.y += 30
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(main_vbox, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(main_vbox, "position:y", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

# ── Feedback visual del input ───────────────────────────────────────────────
func _on_name_changed(new_text: String) -> void:
	var txt = new_text.strip_edges()
	if txt.is_empty():
		name_input.add_theme_stylebox_override("normal", _sf_input_normal)
		name_input.add_theme_stylebox_override("focus",  _sf_input_normal)
	elif txt.length() > 16:
		name_input.add_theme_stylebox_override("normal", _sf_input_error)
		name_input.add_theme_stylebox_override("focus",  _sf_input_error)
	else:
		name_input.add_theme_stylebox_override("normal", _sf_input_ok)
		name_input.add_theme_stylebox_override("focus",  _sf_input_ok)

# ── Crear sala ─────────────────────────────────────────────────────────────
func _on_create_pressed() -> void:
	var username = name_input.text.strip_edges()
	if not _validate_name(username):
		_shake(name_input)
		return
	_set_loading(true)
	NetworkManager.create_server(username)

# ── Unirse ─────────────────────────────────────────────────────────────────
func _on_join_pressed() -> void:
	var username = name_input.text.strip_edges()
	var code     = code_input.text.strip_edges()
	if not _validate_name(username):
		_shake(name_input)
		return
	if code.length() != 4 or not code.is_valid_int():
		_show_error("Ingresa un código de 4 dígitos válido")
		_shake(code_input)
		return
	_set_loading(true)
	NetworkManager.join_by_code(code, username)

# ── Callbacks de red ───────────────────────────────────────────────────────
func _on_server_created(code: String) -> void:
	_set_loading(false)
	_show_success("✔  Sala creada — Código: %s" % code)
	await get_tree().create_timer(2.5).timeout
	SceneManager.go_to_lobby()

func _on_joined_server() -> void:
	_set_loading(false)
	SceneManager.go_to_lobby()

func _on_connection_failed() -> void:
	_set_loading(false)
	_show_error("✖  No se pudo conectar. Verifica el código e intenta de nuevo.")

# ── Volver ─────────────────────────────────────────────────────────────────
func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	SceneManager.go_to_main_menu()

# ── Helpers ────────────────────────────────────────────────────────────────
func _validate_name(username: String) -> bool:
	if username.is_empty():
		_show_error("Ingresa tu nombre antes de continuar")
		return false
	if username.length() > 16:
		_show_error("El nombre no puede tener más de 16 caracteres")
		return false
	return true

func _show_error(msg: String) -> void:
	status_label.modulate = Color(1.0, 0.35, 0.35, 1)
	status_label.text = msg
	status_label.visible = true
	await get_tree().create_timer(3.5).timeout
	status_label.visible = false

func _show_success(msg: String) -> void:
	status_label.modulate = Color(0.3, 1.0, 0.5, 1)
	status_label.text = msg
	status_label.visible = true

func _set_loading(loading: bool) -> void:
	create_btn.disabled = loading
	join_btn.disabled   = loading
	if loading:
		status_label.modulate = Color(0.8, 0.8, 0.85, 0.7)
		status_label.text   = "⏳  Conectando..."
		status_label.visible = true
	else:
		status_label.visible = false

func _shake(node: Control) -> void:
	var origin = node.position
	var tw = create_tween()
	tw.tween_property(node, "position:x", origin.x - 8, 0.05)
	tw.tween_property(node, "position:x", origin.x + 8, 0.05)
	tw.tween_property(node, "position:x", origin.x - 6, 0.05)
	tw.tween_property(node, "position:x", origin.x + 6, 0.05)
	tw.tween_property(node, "position:x", origin.x,     0.05)

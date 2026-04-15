# Scenes/Menus/Multiplayer/MultiplayerMenu.gd
extends Control

@onready var name_input   = $MarginContainer/VBoxContainer/NamePanel/VBoxContainer/NameInput
@onready var code_input   = $MarginContainer/VBoxContainer/CardsContainer/JoinCard/VBoxContainer/IpInput
@onready var status_label = $MarginContainer/VBoxContainer/StatusLabel
@onready var create_btn   = $MarginContainer/VBoxContainer/CardsContainer/CreateCard/VBoxContainer/CreateButton
@onready var join_btn     = $MarginContainer/VBoxContainer/CardsContainer/JoinCard/VBoxContainer/JoinButton
@onready var back_btn     = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	NetworkManager.server_created.connect(_on_server_created)
	NetworkManager.joined_server.connect(_on_joined_server)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	if not NetworkManager.local_username.is_empty():
		name_input.text = NetworkManager.local_username

# ── Crear sala ────────────────────────────────────────────────────────────────
func _on_create_pressed() -> void:
	var username = name_input.text.strip_edges()
	if not _validate_name(username):
		return
	_set_loading(true)
	NetworkManager.create_server(username)

# ── Unirse ────────────────────────────────────────────────────────────────────
func _on_join_pressed() -> void:
	var username = name_input.text.strip_edges()
	var code     = code_input.text.strip_edges()
	if not _validate_name(username):
		return
	if code.length() != 4 or not code.is_valid_int():
		_show_error("Ingresa un código de 4 dígitos")
		return
	_set_loading(true)
	NetworkManager.join_by_code(code, username)

# ── Callbacks de red ──────────────────────────────────────────────────────────
func _on_server_created(code: String) -> void:
	_set_loading(false)
	# Mostrar el código al host para que lo comparta
	status_label.modulate = Color(0.4, 1, 0.6)
	status_label.text = "Código de sala: %s" % code
	await get_tree().create_timer(3.0).timeout
	SceneManager.go_to_lobby()

func _on_joined_server() -> void:
	_set_loading(false)
	SceneManager.go_to_lobby()

func _on_connection_failed() -> void:
	_set_loading(false)
	_show_error("No se pudo conectar. Verifica el código e intenta de nuevo.")

# ── Volver ────────────────────────────────────────────────────────────────────
func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	SceneManager.go_to_main_menu()

# ── Helpers ───────────────────────────────────────────────────────────────────
func _validate_name(username: String) -> bool:
	if username.is_empty():
		_show_error("Ingresa tu nombre antes de continuar")
		return false
	if username.length() > 16:
		_show_error("El nombre no puede tener más de 16 caracteres")
		return false
	return true

func _show_error(msg: String) -> void:
	status_label.text = msg
	status_label.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(3.0).timeout
	status_label.text = ""

func _set_loading(loading: bool) -> void:
	create_btn.disabled = loading
	join_btn.disabled   = loading
	status_label.modulate = Color(1, 1, 1, 0.6)
	status_label.text   = "Conectando..." if loading else ""

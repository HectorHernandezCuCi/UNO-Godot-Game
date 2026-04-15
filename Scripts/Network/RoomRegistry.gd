extends Node

const BROADCAST_PORT = 7778
const BROADCAST_INTERVAL = 2.0

var _room_code: String = ""
var _udp_server: PacketPeerUDP  # usado por el host para escuchar
var _udp_client: PacketPeerUDP  # usado por el cliente para buscar
var _broadcast_timer: Timer

signal room_found(ip: String)
signal room_not_found

# ═══════════════════════════════════════════════
#  HOST — Crear y anunciar sala
# ═══════════════════════════════════════════════
func host_open_room() -> String:
	_room_code = "%04d" % randi_range(1000, 9999)

	# UDP escuchando en broadcast
	_udp_server = PacketPeerUDP.new()
	_udp_server.set_broadcast_enabled(true)
	var err = _udp_server.bind(BROADCAST_PORT)
	if err != OK:
		push_error("RoomRegistry: no se pudo abrir puerto UDP %d" % BROADCAST_PORT)
		return ""

	# Timer para revisar paquetes entrantes
	_broadcast_timer = Timer.new()
	_broadcast_timer.wait_time = 0.1
	_broadcast_timer.autostart = true
	_broadcast_timer.timeout.connect(_host_poll)
	add_child(_broadcast_timer)

	print("RoomRegistry: sala abierta con código %s" % _room_code)
	return _room_code


func host_close_room() -> void:
	_room_code = ""
	if _udp_server:
		_udp_server.close()
		_udp_server = null
	_stop_timer()


# El host escucha paquetes del tipo "FIND:1234"
# y responde "FOUND:1234" al cliente que preguntó
func _host_poll() -> void:
	if not _udp_server:
		return
	while _udp_server.get_available_packet_count() > 0:
		var packet = _udp_server.get_packet()
		var msg    = packet.get_string_from_utf8()
		var sender_ip   = _udp_server.get_packet_ip()
		var sender_port = _udp_server.get_packet_port()

		if msg == "FIND:" + _room_code:
			# Responder directamente al cliente
			var reply = PacketPeerUDP.new()
			reply.set_dest_address(sender_ip, sender_port)
			reply.put_packet(("FOUND:" + _room_code).to_utf8_buffer())
			reply.close()
			print("RoomRegistry: cliente encontró sala desde %s" % sender_ip)

# ═══════════════════════════════════════════════
#  CLIENTE — Buscar sala por código
# ═══════════════════════════════════════════════
func client_find_room(code: String) -> void:
	_udp_client = PacketPeerUDP.new()
	_udp_client.set_broadcast_enabled(true)
	var err = _udp_client.bind(0)  # puerto libre automático
	if err != OK:
		push_error("RoomRegistry: no se pudo crear socket cliente")
		emit_signal("room_not_found")
		return

	# Mandar broadcast cada 0.5s durante 5s máximo
	var attempts = 0
	_broadcast_timer = Timer.new()
	_broadcast_timer.wait_time = 0.5
	_broadcast_timer.autostart = true
	_broadcast_timer.timeout.connect(func():
		attempts += 1
		# Broadcast a toda la red local
		_udp_client.set_dest_address("255.255.255.255", BROADCAST_PORT)
		_udp_client.put_packet(("FIND:" + code).to_utf8_buffer())

		# Revisar si llegó respuesta
		while _udp_client.get_available_packet_count() > 0:
			var packet  = _udp_client.get_packet()
			var host_ip = _udp_client.get_packet_ip()
			var msg     = packet.get_string_from_utf8()

			if msg == "FOUND:" + code:
				_stop_client()
				emit_signal("room_found", host_ip)
				return

		if attempts >= 10:  # 5 segundos sin respuesta
			_stop_client()
			emit_signal("room_not_found")
	)
	add_child(_broadcast_timer)


func _stop_client() -> void:
	if _udp_client:
		_udp_client.close()
		_udp_client = null
	_stop_timer()


func _stop_timer() -> void:
	if _broadcast_timer:
		_broadcast_timer.stop()
		_broadcast_timer.queue_free()
		_broadcast_timer = null

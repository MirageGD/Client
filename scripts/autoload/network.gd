extends Node

signal connected
signal disconnected(code: int, reason: String)
signal message(type: String, payload: Dictionary)

@onready var _game_url: String = ProjectSettings.get_setting("mirage/server/address") + "api/v1/game"

var _socket := WebSocketPeer.new()
var _active := false
var _last_state := WebSocketPeer.STATE_CLOSED

func _ready() -> void:
	_game_url = _game_url.replace("https://", "wss://").replace("http://", "ws://")
	
	disconnected.connect(func(_code: int, _reason: String) -> void:
		SignalBus.goto_login.emit()
		SignalBus.critical_error.emit(
			"The connection with the server has been lost."
		))

func connect_to_server(token: String) -> void:
	var url = _game_url + "/" + token
	
	var err := _socket.connect_to_url(url, TLSOptions.client())
	if err != OK:
		push_error("[Network] failed to connect to server: %s" % err)
	
	_last_state = WebSocketPeer.STATE_CONNECTING
	_active = true

func disconnect_from_server() -> void:
	_socket.close()
	_active = false

func _process(_delta: float) -> void:
	if not _active:
		return
	
	_socket.poll()
	var state = _socket.get_ready_state()
	
	if state != _last_state:
		_on_state_changed(state)
		_last_state = state
	
	if state == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count() > 0:
			var data = _socket.get_packet().get_string_from_utf8()
			_parse_packet(data)

func _parse_packet(data: String) -> void:
	print_debug("Received: %s" % data)
	
	var json = JSON.parse_string(data)
	if json is Dictionary:
		var type: String = json.get("type", "")
		if type.is_empty():
			return
		
		var payload = json.get("payload")
		if payload is not Dictionary:
			return
		
		message.emit(type, payload)

func _on_state_changed(new_state: int) -> void:
	match new_state:
		WebSocketPeer.STATE_OPEN:
			connected.emit()
		WebSocketPeer.STATE_CLOSED:
			disconnected.emit(_socket.get_close_code(), _socket.get_close_reason())
			_active = false

func send(data: Dictionary) -> void:
	_socket.send_text(JSON.stringify(data))

func send_move(direction: String) -> void:
	send({
		"type": "move",
		"direction": direction
	})

func send_direction(direction: String) -> void:
	send({
		"type": "direction",
		"direction": direction
	})

func send_attack() -> void:
	send({
		"type": "attack"
	})

func send_chat_message(chat_message: String) -> void:
	send({
		"type": "chat",
		"message": chat_message
	})

func send_warp_request() -> void:
	send({
		"type": "warp"
	})

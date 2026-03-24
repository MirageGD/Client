extends Control
class_name PageCharacterList

const BOX_CONFIRM = preload("uid://cowe8deq5x26c")

@onready var _character_list: ItemList = %CharacterList
@onready var _button_new: Button = %ButtonNew
@onready var _button_delete: Button = %ButtonDelete
@onready var _button_select: Button = %ButtonSelect
@onready var _http_list: HTTPRequest = %HTTPList
@onready var _http_delete: HTTPRequest = %HTTPDelete
@onready var _http_get_token: HTTPRequest = %HTTPGetToken
@onready var _characters_url: String = ProjectSettings.get_setting("mirage/server/address") + "characters"

var _characters: Array[String]

func _ready() -> void:
	_button_new.disabled = false
	_fetch_character_list()

func _on_character_selected(index: int) -> void:
	var is_selected := index != -1
	_button_delete.disabled = not is_selected
	_button_select.disabled = not is_selected

func _on_button_new_pressed() -> void:
	SignalBus.goto_character_create.emit()

func _on_button_delete_pressed() -> void:
	var selected_items = _character_list.get_selected_items()
	if len(selected_items) == 0:
		return
	
	var selected_item: int = selected_items[0]
	
	var confirm: BoxConfirm = BOX_CONFIRM.instantiate()
	
	confirm.text = "Are you sure you want to delete the selected character?"
	confirm.accept.connect(func() -> void:
		_delete_character(selected_item))
	
	add_child(confirm)

func _on_button_select_pressed() -> void:
	var selected_items = _character_list.get_selected_items()
	if selected_items.size() == 0:
		return
	
	_select_character(selected_items[0])

func _on_button_cancel_pressed() -> void:
	SignalBus.goto_login.emit()

func _fetch_character_list() -> void:
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + Session.auth_token
	]
	
	_http_list.request(_characters_url, headers)

func _delete_character(index: int) -> void:
	if index >= _characters.size():
		return
	
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + Session.auth_token
	]
	
	var url := _characters_url + "/" + _characters[index]
	
	_http_delete.request(url, headers, HTTPClient.METHOD_DELETE)

func _select_character(index: int) -> void:
	if index >= _characters.size():
		return
	
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + Session.auth_token
	]
	
	var url := _characters_url + "/" + _characters[index] + "/token"
	
	_http_get_token.request(url, headers)

func _start_game(json: PackedByteArray) -> void:
	var body = JSON.parse_string(json.get_string_from_utf8())
	if body is Dictionary:
		var token: String = body.get("token", "")
		if token.is_empty():
			_on_error("Received empty token from server")
			return
		
		Network.connect_to_server(token)
		
		SignalBus.goto_game.emit()
		
		queue_free()
		return
	
	_on_error("Received bad response from server.")
	return

func _on_error(error_message: String) -> void:
	SignalBus.critical_error.emit(error_message)

func _on_error_response(response_code: int) -> void:
	match response_code:
		401: _on_unauthorized()
		404: _on_error("The character service is not available. Please try again later.")
		_: _on_error("An unexpected error occured. Please try again later.")

func _on_unauthorized() -> void:
	SignalBus.goto_login.emit()
	_on_error("Session expired")

func _update_list(json: PackedByteArray) -> void:
	_characters.clear()
	_character_list.clear()
	
	var body = JSON.parse_string(json.get_string_from_utf8())
	if body is Dictionary:
		var characters = body.get("characters", [])
		for character in characters:
			if not character is Dictionary:
				continue
			
			var character_name: String = character.get("name", "")
			var character_level: int = character.get("level", 1)
			
			_characters.append(character_name)
			_character_list.add_item("%s (lv. %d)" % [character_name, character_level])
		
		if _characters.size() > 0:
			_character_list.select(0)
			_on_character_selected(0)

func _on_http_list_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK:
		_on_error("Unable to connect to server")
		return
	
	if response_code == 200:
		_update_list(body)
		return
	
	_on_error_response(response_code)

func _on_http_delete_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != OK:
		_on_error("Unable to connect to server")
		return
	
	if response_code == 200:
		_fetch_character_list()
		return
	
	_on_error_response(response_code)

func _on_http_get_token_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK:
		_on_error("Unable to connect to server")
		return
	
	if response_code == 200:
		_start_game(body)
		return
	
	_on_error_response(response_code)

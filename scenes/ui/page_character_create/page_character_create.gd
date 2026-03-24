extends Control
class_name PageCharacterCreate

const MIN_CHARACTER_NAME_LENGTH: int = 5

@onready var _edit_character_name: LineEdit = %CharacterNameLineEdit
@onready var _button_create: Button = %ButtonCreate
@onready var _button_cancel: Button = %ButtonCancel
@onready var _http: HTTPRequest = %HTTP
@onready var _characters_url: String = ProjectSettings.get_setting("mirage/server/address") + "characters"

func _ready() -> void:
	_set_enabled(true)
	_edit_character_name.grab_focus()

func _set_enabled(enabled: bool) -> void:
	_edit_character_name.editable = enabled
	_button_create.disabled = not enabled or not _can_submit()
	_button_cancel.disabled = not enabled

func _can_submit() -> bool:
	return _edit_character_name.text.length() >= MIN_CHARACTER_NAME_LENGTH

func _on_line_edit_text_changed(_new_text: String) -> void:
	_button_create.disabled = not _can_submit()

func _on_line_edit_text_submitted(_new_text: String) -> void:
	if _can_submit():
		_submit()

func _on_button_create_pressed() -> void:
	_submit()

func _on_button_cancel_pressed() -> void:
	SignalBus.goto_character_list.emit()

func _submit() -> void:
	_set_enabled(false)
	
	var character_name := _edit_character_name.text
	
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + Session.auth_token
	]
	
	var body := {
		"characterName": character_name
	}
	
	_http.request(_characters_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_error(error_message: String) -> void:
	SignalBus.critical_error.emit(error_message)
	_set_enabled(true)

func _on_unauthorized() -> void:
	SignalBus.goto_login.emit()
	_on_error("Session expired")

func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != OK:
		_on_error("Unable to connect to server")
		return
	
	if response_code == 200:
		SignalBus.goto_character_list.emit()
		return
	
	match response_code:
		401: _on_unauthorized()
		404: _on_error("The character service is not available. Please try again later.")
		409: _on_error("A character with this name already exists.")
		_: _on_error("An unexpected error occured. Please try again later.")

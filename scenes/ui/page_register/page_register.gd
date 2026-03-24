extends Control
class_name PageRegister

const MIN_ACCOUNT_NAME_LENGTH := 5

@onready var _edit_account: LineEdit = %AccountLineEdit
@onready var _edit_password: LineEdit = %PasswordLineEdit
@onready var _edit_repeat_password: LineEdit = %RepeatPasswordLineEdit
@onready var _button_register: Button = %RegisterButton
@onready var _http: HTTPRequest = %HTTP
@onready var _register_url: String = ProjectSettings.get_setting("mirage/server/address") + "register"

func _ready() -> void:
	_set_enabled(true)
	_edit_account.grab_focus()

func _set_enabled(enabled: bool) -> void:
	_edit_account.editable = enabled
	_edit_password.editable = enabled
	_edit_repeat_password.editable = enabled
	_button_register.disabled = not enabled or not _can_submit()

func _can_submit() -> bool:
	if _edit_account.text.length() < MIN_ACCOUNT_NAME_LENGTH:
		return false
	
	if _edit_password.text.is_empty():
		return false
	
	if _edit_password.text != _edit_repeat_password.text:
		return false
	
	return true

func _on_line_edit_text_changed(_new_text: String) -> void:
	_button_register.disabled = not _can_submit()

func _on_line_edit_text_submitted(_new_text: String) -> void:
	if _can_submit():
		_submit()

func _on_login_button_pressed() -> void:
	_submit()

func _submit() -> void:
	_set_enabled(false)
	
	var account_name := _edit_account.text
	var password := _edit_password.text
	
	var body := {
		"accountName": account_name,
		"password": password
	}
	
	_http.request(_register_url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_register_ok(json: PackedByteArray) -> void:
	var body = JSON.parse_string(json.get_string_from_utf8())
	if body is Dictionary:
		var token: String = body.get("token", "")
		if token.is_empty():
			_on_error("Received empty token from server")
			return
		SignalBus.critical_error.emit("Your account has been created.")
		
		queue_free()
		return
	
	_on_error("Received bad response from server.")
	return

func _on_register_failed(response_code: int) -> void:
	match response_code:
		404: _on_error("The account registration service is not available. Please try again later.")
		409: _on_error("The specified account name is already in use.")
		_: _on_error("An unexpected error occured. Please try again later.")

func _on_error(error_message: String) -> void:
	SignalBus.critical_error.emit(error_message)
	_set_enabled(true)

func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK:
		_on_error("Unable to connect to server")
		return
	
	if response_code == 200:
		_on_register_ok(body)
		return
	
	_on_register_failed(response_code)

func _on_login_link_button_pressed() -> void:
	SignalBus.goto_login.emit()

extends Control
class_name PanelChat

@onready var _chat_messages: RichTextLabel = %ChatMessages
@onready var _chat_line: LineEdit = %ChatLineEdit

func _ready() -> void:
	SignalBus.chat.connect(_chat)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("chat"):
		_chat_line.grab_focus()

func _on_chat_line_submitted(new_text: String) -> void:
	if not new_text.is_empty():
		Network.send_chat_message(new_text)
	_chat_line.release_focus()

func _on_chat_line_focus_exited() -> void:
	_chat_line.text = ""

func _chat(payload: Dictionary) -> void:
	var message: String = payload.get("message", "")
	var message_color: String = payload.get("color", "#ffffff")
	if message.is_empty():
		return
	
	var sender = payload.get("sender_name", null)
	if sender and not sender.is_empty():
		var sender_color = payload.get("sender_color", message_color)
		
		_chat_messages.append_text("[color=%s]%s[/color]: " % [sender_color, sender])
	
	_chat_messages.append_text("[color=%s]%s[/color]\n" % [message_color, message])

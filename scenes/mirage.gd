extends Control

const BOX_ALERT = preload("uid://klp2wjh5bx5o")

const GAME = preload("uid://vfiguc0irvsf")

const PAGE_LOGIN = preload("uid://bihdv051ygw2p")
const PAGE_REGISTER = preload("uid://dhm5uw575wilx")
const PAGE_CHARACTER_LIST = preload("uid://cu4hmfomsyys8")
const PAGE_CHARACTER_CREATE = preload("uid://dj2mwcdedm34p")

var _current_scene: Node

func _ready() -> void:
	SignalBus.goto_login.connect(_goto_login)
	SignalBus.goto_register.connect(_goto_register)
	SignalBus.goto_character_list.connect(_goto_character_list)
	SignalBus.goto_character_create.connect(_goto_character_create)
	SignalBus.goto_game.connect(_goto_game)
	SignalBus.critical_error.connect(_critical_error)
	_goto_login()

func _goto_login() -> void:
	_show_page(PAGE_LOGIN)

func _goto_register() -> void:
	_show_page(PAGE_REGISTER)

func _goto_character_list() -> void:
	_show_page(PAGE_CHARACTER_LIST)

func _goto_character_create() -> void:
	_show_page(PAGE_CHARACTER_CREATE)

func _goto_game() -> void:
	_show_page(GAME)

func _critical_error(error_message: String) -> void:
	var alert: BoxAlert = BOX_ALERT.instantiate()
	alert.text = error_message
	add_child(alert)

func _show_page(page_scene: PackedScene) -> void:
	if _current_scene:
		_current_scene.queue_free()
	
	_current_scene = page_scene.instantiate()
	
	add_child(_current_scene)

extends Node2D
class_name Entity

const CONTENT_CACHE_DIR := "user://content_cache/"

@onready var _sprite: Sprite2D = %Sprite
@onready var _camera: Camera2D = %Camera
@onready var _animation_player: AnimationPlayer = %AnimationPlayer
@onready var _sound_hurt: AudioStreamPlayer2D = $SoundHurt
@onready var _sound_level_up: AudioStreamPlayer2D = $SoundLevelUp
@onready var _floating_text: Node2D = %FloatingText
@onready var _label_name: Label = %NameLabel
@onready var _content_url: String = ProjectSettings.get_setting("mirage/server/address") + "content/"
@onready var _audio_listener: AudioListener2D = %AudioListener2D

var is_local_player := false
var entity_name: String
var current_direction := "down"
var current_tile := Vector2i.ZERO
var map: Map
var tile_checker: Callable
var tile_size := Vector2i(32, 32)
var sprite_path: String

var _move_tween: Tween
var _can_attack := true
var _can_move := true

func _ready() -> void:
	_label_name.text = entity_name
	change_direction(current_direction)
	_return_idle()
	if is_local_player:
		_audio_listener.make_current()
		_camera.enabled = true
		map.map_loaded.connect(func() -> void:
			tile_size = map.tile_size
			_update_camera())
	await _load_sprite()

func _load_sprite() -> void:
	if sprite_path.is_empty():
		return
	
	var sprite_local_path := CONTENT_CACHE_DIR.path_join(sprite_path)
	var sprite_url := _content_url + sprite_path
	
	if not await ContentDownloader.download(sprite_url, sprite_local_path):
		return
	
	var image = Image.new()
	
	var err := image.load(sprite_local_path)
	if err != OK:
		push_error("[Entity] failed to load sprite '%s'" % sprite_local_path)
		return
	
	_sprite.texture = ImageTexture.create_from_image(image)

func _update_camera() -> void:
	_camera.limit_left = 0
	_camera.limit_right = map.map_width * tile_size.x
	_camera.limit_top = 0
	_camera.limit_bottom = map.map_height * tile_size.y

func _process(_delta: float) -> void:
	if not is_local_player:
		return

	if get_viewport().gui_get_focus_owner() != null:
		return
	
	if _can_move and _can_attack:
		if Input.is_action_pressed("attack"):
			_attack_local()
		elif Input.is_action_pressed("move_up"):
			_move_local("up")
		elif Input.is_action_pressed("move_down"):
			_move_local("down")
		elif Input.is_action_pressed("move_left"):
			_move_local("left")
		elif Input.is_action_pressed("move_right"):
			_move_local("right")

func _attack_local() -> void:
	_can_attack = false
	
	Network.send_attack()
	
	_animation_player.play("attack_" + current_direction)
	
	await _animation_player.animation_finished
	await get_tree().create_timer(0.25).timeout
	
	_can_attack = true
	
	_return_idle()

func _attack(direction: String) -> void:
	var animation_name := "attack_" + direction
	_animation_player.play(animation_name)

func _get_tile_coords(coords: Vector2) -> Vector2i:
	var tile_x := int(coords.x / tile_size.x)
	var tile_y := int(coords.y / tile_size.y)
	return Vector2i(tile_x, tile_y)

func _move_local(direction: String) -> void:
	var target = position + _get_direction_vector(direction)
	if target == position:
		return
	
	var target_tile := _get_tile_coords(target)
	if map and (not map.is_passable(target_tile) or tile_checker.call(target_tile)):
		if current_direction != direction:
			change_direction(direction)
			Network.send_direction(current_direction)
		return
	
	current_tile = target_tile
	
	_can_move = false
	
	Network.send_move(direction)
	
	change_direction(direction)
	
	_animation_player.play("walk_" + direction)
	
	var tween = create_tween()
	
	tween.tween_property(self, "position", target, 0.4)
	tween.play()
	
	await tween.finished
	
	_can_move = true
	
	_check_for_warp(target_tile)
	_return_idle()

func _check_for_warp(tile_coords: Vector2i) -> void:
	if map and map.has_object_of_type_at("warp", tile_coords):
		Network.send_warp_request()

func _return_idle() -> void:
	_animation_player.play("idle_" + current_direction)

func change_direction(direction: String) -> void:
	current_direction = direction
	_return_idle()

func move(source_tile: Vector2i, direction: String) -> void:
	if is_local_player:
		return
	
	var target := _get_move_target(source_tile, direction)
	if target == position:
		return
	
	change_direction(direction)
	_move_to(target)

func _get_move_target(source_tile: Vector2i, direction: String) -> Vector2:
	var source_position = Vector2(source_tile.x * 32, source_tile.y * 32)
	return source_position + _get_direction_vector(direction)

func _get_direction_vector(direction: String) -> Vector2:
	match direction:
		"up": return Vector2(0, -tile_size.y)
		"down": return Vector2(0, tile_size.y)
		"left": return Vector2(-tile_size.x, 0)
		"right": return Vector2(tile_size.x, 0)
		_: return Vector2.ZERO

func _move_to(target: Vector2):
	if target == position:
		return
	
	@warning_ignore("integer_division")
	current_tile = Vector2i(int(target.x) / tile_size.x, int(target.y) / tile_size.y)
	
	if _move_tween and _move_tween.is_running():
		_move_tween.stop()
	
	_animation_player.play("walk_" + current_direction)
	
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target, 0.4)
	_move_tween.finished.connect(func() -> void:
		_return_idle())
	_move_tween.play()

func _exit_tree() -> void:
	if _label_name:
		_label_name.queue_free()

func attack(direction: String) -> void:
	change_direction(direction)
	
	_animation_player.play("attack_" + current_direction)
	
	await _animation_player.animation_finished
	
	_return_idle()

func hurt(damage: int) -> void:
	_sound_hurt.play()
	_floating_text.emit(str(damage))

func level_up(_new_level: int) -> void:
	_sound_level_up.play()

extends Node2D

const FNT_PIXEL_OPERATOR = preload("uid://dgsf2x1sgy0ll")

func emit(text: String) -> void:
	var label = Label.new()
	
	label.text = text
	label.z_index = 60
	label.label_settings = LabelSettings.new()
	label.label_settings.font_color = Color.WHITE
	label.label_settings.font_size = 16
	label.label_settings.font = FNT_PIXEL_OPERATOR
	label.label_settings.outline_color = Color.BLACK
	label.label_settings.outline_size = 2
	
	call_deferred("add_child", label)
	
	await label.resized
	
	var center := Vector2(label.size / 2)
	
	label.pivot_offset = center
	label.position = -center
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 24, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y, 0.5).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(label, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	
	label.queue_free()
	

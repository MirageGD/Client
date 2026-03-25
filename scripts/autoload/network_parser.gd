extends Node

func _ready() -> void:
	Network.message.connect(_message)

func _message(type: String, payload: Dictionary) -> void:
	match type.to_lower():
		"map_init": SignalBus.map_init.emit(payload)
		
		"entity_attack": SignalBus.entity_attack.emit(payload)
		"entity_death": SignalBus.entity_death.emit(payload)
		"entity_direction": SignalBus.entity_direction.emit(payload)
		"entity_health": SignalBus.entity_health.emit(payload)
		"entity_hurt": SignalBus.entity_hurt.emit(payload)
		"entity_joined": SignalBus.entity_joined.emit(payload)
		"entity_left": SignalBus.entity_left.emit(payload)
		"entity_leveled_up": SignalBus.entity_leveled_up.emit(payload)
		"entity_moved": SignalBus.entity_moved.emit(payload)
		
		"player_xp": SignalBus.player_xp.emit(payload)
		"player_stats": SignalBus.player_stats.emit(payload)
		
		"chat": SignalBus.chat.emit(payload)

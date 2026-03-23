extends Node

signal goto_login
signal goto_register
signal goto_character_list
signal goto_character_create
signal goto_game

signal critical_error(message: String)

signal map_init(data: Dictionary)

signal entity_attack(payload: Dictionary)
signal entity_death(payload: Dictionary)
signal entity_direction(payload: Dictionary)
signal entity_health(payload: Dictionary)
signal entity_hurt(payload: Dictionary)
signal entity_joined(payload: Dictionary)
signal entity_left(payload: Dictionary)
signal entity_leveled_up(payload: Dictionary)
signal entity_moved(payload: Dictionary)

signal player_xp(payload: Dictionary)

signal chat(payload: Dictionary)

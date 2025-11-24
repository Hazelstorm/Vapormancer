class_name Enemy extends Tile

enum Type {
	Water,
	Fire,
	Steam,
}

@export var hp: int
@export var attack: int
@export var steam: int
@export var type: Type
@export_storage var alive := true

func get_hp() -> int:
	return hp * stacks

func get_attack() -> int:
	return attack * stacks

func get_steam() -> int:
	return steam * stacks

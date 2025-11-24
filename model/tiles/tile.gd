class_name Tile extends Resource

signal mouse_entered
signal mouse_exited
signal stacks_changed

@export var tile_name: String
var actor: TileActor

@export_storage var id: int
@export_storage var coords: Vector2i
@export_storage var stacks := 1:
	set(value):
		stacks = value
		stacks_changed.emit()

func _on_control_mouse_entered():
	mouse_entered.emit()

func _on_control_mouse_exited():
	mouse_exited.emit()

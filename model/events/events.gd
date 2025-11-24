@abstract class_name Event extends Resource

static var events_path: String = "res://model/events/"

@export var is_reversed := false
@export var coords: Vector2i
func do(game: Game) -> bool:
	@warning_ignore("standalone_ternary")
	return _undo(game) if is_reversed else _do(game)
func undo(game: Game) -> bool:
	@warning_ignore("standalone_ternary")
	return _do(game) if is_reversed else _undo(game)
func reversed():
	var clone = duplicate()
	clone.is_reversed = !clone.is_reversed
	return clone
@abstract func _do(game: Game) -> bool
@abstract func _undo(game: Game) -> bool
@abstract func as_string() -> String

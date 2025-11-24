class_name MoveEvent extends Event

@export var tile: Tile
@export var from: Vector2i
@export var to: Vector2i

func setup(_tile: Tile, _to: Vector2i):
	tile = _tile
	to = _to
	if tile:
		from = tile.coords
	return self
func _do(game: Game) -> bool:
	if !tile:
		print("ERROR MoveEvent @ (%d,%d) -> (%d,%d) failed. Reason: null tile" % [coords.x, coords.y, to.x, to.y])
		return false
	game.move_tile(tile, to)
	return true
func _undo(game: Game) -> bool:
	if !tile:
		print("ERROR Undo MoveEvent @ (%d,%d) -> (%d,%d) failed. Reason: null tile" % [coords.x, coords.y, to.x, to.y])
		return false
	game.move_tile(tile, from)
	return true
func as_string() -> String:
	return "Move"

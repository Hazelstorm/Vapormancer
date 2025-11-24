class_name UseItemEvent extends Event

@export var item: Item
@export var name: String
@export var idx: int

func setup(_item: Item, game: Game):
	item = _item
	name = item.tile_name
	idx = game.find_item(item)
	return self

func _do(game: Game) -> bool:
	if !item:
		print("ERROR UseItemEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	
	if item.effect.double_scroll:
		game.mag *= 2
	if item.effect.swap_scroll:
		game.mag *= -1
	return true

func _undo(game: Game) -> bool:
	if !item:
		print("ERROR Undo UseItemEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	
	if item.effect.double_scroll:
		game.mag /= 2
	if item.effect.swap_scroll:
		game.mag *= -1
	return true

func as_string() -> String:
	return "Use %s" % name

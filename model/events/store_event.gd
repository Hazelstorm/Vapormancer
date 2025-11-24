class_name StoreEvent extends Event

@export var item: Item
@export var name: String
@export var stacks: int

func setup(_item: Item, game: Game):
	item = _item
	if item:
		name = item.tile_name
		stacks = item.stacks
	return self

func _do(game: Game) -> bool:
	if !item:
		print("ERROR StoreItemEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	if item.actor:
		item.actor.hide()
	item.collected = true
	return true

func _undo(game: Game) -> bool:
	if !item:
		print("ERROR Undo StoreEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	if item.actor:
		item.actor.show()
	item.collected = false
	return true
func as_string() -> String:
	if stacks == 1:
		return "Get %s" % name
	return "Get %s x %d" % [name, stacks]

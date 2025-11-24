class_name LoseItemEvent extends Event

@export var item: Item
@export var idx: int
@export var last: bool

func setup(_item: Item, game: Game):
	item = _item
	if item:
		idx = game.find_item(item)
		last = (item.stacks == 1)
	return self

func _do(game: Game) -> bool:
	if !item:
		print("ERROR LoseItemEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	game.inventory[idx].stacks -= 1
	if last:
		game.inventory.remove_at(idx)
	return true
func _undo(game: Game) -> bool:
	if !item:
		print("ERROR Undo LoseItemEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	if last:
		var inv_item := InvItem.new()
		inv_item.item = item
		game.inventory.insert(idx, inv_item)
	game.inventory[idx].stacks += 1
	return true
func as_string() -> String:
	return ""

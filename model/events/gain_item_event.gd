class_name GainItemEvent extends Event

@export var item: Item
@export var idx: int

func setup(_item: Item, game: Game):
	item = _item
	if item:
		idx = game.find_item(item)
	return self

func _do(game: Game) -> bool:
	if !item:
		print("ERROR GainItemEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	if idx == -1:
		var inv_item = InvItem.new()
		inv_item.item = item
		inv_item.stacks = item.stacks
		game.inventory.append(inv_item)
	else:
		game.inventory[idx].stacks += item.stacks
	return true
func _undo(game: Game) -> bool:
	if !item:
		print("ERROR GainItemEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	if idx == -1:
		game.inventory.remove_at(game.inventory.size() - 1)
	else:
		game.inventory[idx].stacks -= item.stacks
	return true
func as_string() -> String:
	return ""

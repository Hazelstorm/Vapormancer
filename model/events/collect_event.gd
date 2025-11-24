class_name CollectEvent extends Event

@export var item: Item

func setup(_item: Item):
	item = _item
	return self

func _do(game: Game) -> bool:
	if !item:
		print("ERROR CollectEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	if item.actor:
		item.actor.hide()
	item.collected = true
	if item.effect.healing != 0:
		game.hp += item.effect.healing * item.stacks
	if item.effect.mag != 0:
		game.mag += item.effect.mag * item.stacks
	if item.effect.steam != 0:
		var amt = item.effect.steam * item.stacks
		for inv_item in game.inventory:
			if inv_item.item.effect.steam_orb:
				amt *= 2
		game.steam += amt
	if item.effect.defense != 0:
		game.defense += item.effect.defense * item.stacks
	if item.effect.double_scroll:
		game.mag *= 2
	if item.effect.swap_scroll:
		game.mag *= -1
	return true

func _undo(game: Game) -> bool:
	if !item:
		print("ERROR Undo CollectEvent @ (%d,%d) failed. Reason: null item" % [coords.x, coords.y])
		return false
	if item.actor:
		item.actor.show()
	item.collected = false
	if item.effect.healing != 0:
		game.hp -= item.effect.healing * item.stacks
	if item.effect.mag != 0:
		game.mag -= item.effect.mag * item.stacks
	if item.effect.steam != 0:
		var amt = item.effect.steam * item.stacks
		for inv_item in game.inventory:
			if inv_item.item.effect.steam_orb:
				amt *= 2
		game.steam -= amt
	if item.effect.defense != 0:
		game.defense -= item.effect.defense * item.stacks
	if item.effect.double_scroll:
		game.mag /= 2
	if item.effect.swap_scroll:
		game.mag *= -1
	return true

func as_string() -> String:
	return "Collect %s" % item.tile_name

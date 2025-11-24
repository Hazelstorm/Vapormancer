class_name BattleEvent extends Event

@export var enemy: Enemy
@export var dmg: int

func setup(_enemy: Enemy, game: Game):
	enemy = _enemy
	if enemy:
		dmg = game.get_damage(enemy)
	return self

func _do(game: Game) -> bool:
	if !enemy:
		print("ERROR BattleEvent @ (%d,%d) failed. Reason: null enemy" % [coords.x, coords.y])
		return false
	if enemy.actor:
		enemy.actor.hide()
	enemy.alive = false
	game.hp -= dmg
	for inv_item in game.inventory:
		if inv_item.item.effect.lantern:
			if enemy.tile_name == "Water Sprite":
				game.mag += 10 * enemy.stacks
			if enemy.tile_name == "Fire Sprite":
				game.mag -= 10 * enemy.stacks
			break
	return true
	
func _undo(game: Game) -> bool:
	if !enemy:
		print("ERROR Undo BattleEvent @ (%d,%d) failed. Reason: null enemy" % [coords.x, coords.y])
		return false
	if enemy.actor:
		enemy.actor.show()
	enemy.alive = true
	game.hp += dmg
	#game.steam -= steam
	for inv_item in game.inventory:
		if inv_item.item.effect.lantern:
			if enemy.tile_name == "Water Sprite":
				game.mag -= 10 * enemy.stacks
			if enemy.tile_name == "Fire Sprite":
				game.mag += 10 * enemy.stacks
			break
	return true
func as_string() -> String:
	return "Battle (-%dHP)" % dmg

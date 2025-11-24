class_name Game extends Resource

static var level_size := Vector2i(37, 27)
static var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

@export var tiles: Dictionary[int, Tile]
@export var tiles_at: Dictionary[Vector2i, Array]
@export var inventory: Array[InvItem]
var player: Player:
	get():
		return _get_player()
var goal: Goal:
	get():
		return _get_goal()

@export var hp := 50
@export var mag := 0 # water positive, fire negative
@export var steam := 1
@export var defense := 0

func add_tile(tile: Tile):
	tiles[tile.id] = tile
	if tile.coords not in tiles_at:
		tiles_at[tile.coords] = []
	tiles_at[tile.coords].append(tile)

func remove_tile(tile: Tile):
	tiles.erase(tile.id)
	tiles_at[tile.coords].erase(tile)

func move_tile(tile: Tile, coords: Vector2i):
	tiles_at[tile.coords].erase(tile)
	if coords not in tiles_at:
		tiles_at[coords] = []
	tiles_at[coords].append(tile)
	tile.coords = coords

func get_tile(id: int) -> Tile:
	if id in tiles:
		return tiles[id]
	return null

func get_tile_at(coords: Vector2i) -> Tile:
	if coords not in tiles_at:
		return null
	
	var return_tile = null
	for tile in tiles_at[coords]:
		if tile is Enemy and !tile.alive:
			continue
		if tile is Item and tile.collected:
			continue
		if tile is Lock and !tile.locked:
			continue
		if tile.coords == coords:
			if tile is Player:
				return_tile = tile
			else:
				return tile
	return return_tile

func _get_player() -> Player:
	for id in tiles:
		var tile := tiles[id]
		if tile is Player:
			return tile
	return null

func _get_goal() -> Goal:
	for id in tiles:
		var tile := tiles[id]
		if tile is Goal:
			return tile
	return null

func get_attack(enemy: Enemy):
	match enemy.type:
		Enemy.Type.Water:
			return steam + (-mag if mag < 0 else 0)
		Enemy.Type.Fire:
			return steam + (mag if mag > 0 else 0)
		Enemy.Type.Steam:
			return steam

func get_turns(enemy: Enemy) -> int:
	if get_attack(enemy) == 0:
		return 9999
	@warning_ignore("integer_division")
	return (enemy.get_hp() - 1) / get_attack(enemy)

func get_damage(enemy: Enemy) -> int:
	var shield = 0
	var armor = defense
	for inv_item in inventory:
		shield += inv_item.item.effect.shield * inv_item.stacks
		armor += inv_item.item.effect.armor * inv_item.stacks
	return max(0, get_turns(enemy) - shield) * max(0, enemy.get_attack() - armor)

# returns index the item is found at, or -1
func find_item(item: Item) -> int:
	for i in inventory.size():
		if inventory[i].item.tile_name == item.tile_name:
			return i
	return -1

func get_help_string(enemy: Enemy) -> String:
	var help_string_items: Array[String] = []
	
	@warning_ignore("integer_division")
	var to_help = (enemy.get_hp() - 1) / get_turns(enemy) + 1 if get_turns(enemy) != 0 else -1
	@warning_ignore("integer_division")
	var to_hurt = get_attack(enemy) - (enemy.get_hp() - 1) / ((enemy.get_hp() - 1) / get_attack(enemy) + 1)
	
	match enemy.type:
		Enemy.Type.Water:
			if get_turns(enemy) != 0:
				help_string_items.append("%d [color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color] or %d [shake rate=10.0 level=3 connected=0]Steam[/shake] would help." % [
					to_help - steam + mag,
					to_help - steam + min(0, mag)
				])
			@warning_ignore("integer_division")
			if (enemy.get_hp() - 1) / steam > get_turns(enemy):
				help_string_items.append("%d [outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color] would hurt." % [
					to_hurt
				])
		Enemy.Type.Fire:
			if get_turns(enemy) != 0:
				help_string_items.append("%d [outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color] or %d [shake rate=10.0 level=3 connected=0]Steam[/shake] would help." % [
					to_help - steam - mag,
					to_help - steam - max(0, mag)
				])
			@warning_ignore("integer_division")
			if (enemy.get_hp() - 1) / steam > get_turns(enemy):
				help_string_items.append("%d [color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color] would hurt." % [
					to_hurt
				])
		Enemy.Type.Steam:
			if get_turns(enemy) != 0:
				help_string_items.append("%d [shake rate=10.0 level=3 connected=0]Steam[/shake] would help." % [to_help - steam])
	return "\n".join(help_string_items)

func get_win_string():
	return (
		"[color=#19011a][outline_color=#ffebd8][outline_size=4]Victory![/outline_size][/outline_color][/color]\n\n" +
		"HP: %d x 1 = %d\n" +
		"MAG: %d x 1 = %d\n" +
		"Steam: %d x 10 = %d\n" +
		"[u]Final Score: %d[/u]"
	) % [
		hp,
		hp * 1,
		abs(mag),
		abs(mag) * 1,
		steam,
		steam * 10,
		hp + abs(mag) + steam * 10
	]

var astar := AStarGrid2D.new()
func setup_astar():
	astar.region = Rect2i(Vector2i.ZERO, level_size)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
func update_astar():
	for id in tiles:
		var tile := tiles[id]
		if !astar.is_in_boundsv(tile.coords):
			continue
		if tile is Wall and !tile.destroyed:
			astar.set_point_solid(tile.coords, true)
			continue
		if tile is Lock and tile.locked:
			astar.set_point_solid(tile.coords, true)
			continue
		if tile is Enemy and tile.alive:
			astar.set_point_solid(tile.coords, true)
			continue
		if tile is Item and !tile.collected:
			astar.set_point_solid(tile.coords, true)
			continue
		if tile is Gate and !tile.is_passable(mag):
			astar.set_point_solid(tile.coords, true)
			continue
		astar.set_point_solid(tile.coords, false)

func pathfind(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var solid = astar.is_point_solid(end)
	astar.set_point_solid(end, false)
	var path = astar.get_id_path(start, end)
	astar.set_point_solid(end, solid)
	return path

func do_move(coords: Vector2i, undo: Undo, sound: SoundServer = null) -> bool:
	if coords.x < 0 or coords.y < 0 or coords.x >= level_size.x or coords.y > level_size.y:
		return false
	
	update_astar()
	var path = pathfind(player.coords, coords)
	if path:
		var target_tile = get_tile_at(coords)
		var move_event = MoveEvent.new().setup(player, coords)
		move_event.coords = coords
		if target_tile is Wall:
			if !target_tile.destroyed:
				for inv_item in inventory:
					if inv_item.item.effect.pickaxe:
						var lose_item_event = LoseItemEvent.new().setup(inv_item, self)
						var unlock_event = UnlockEvent.new().setup(target_tile)
						unlock_event.coords = coords
						undo.commit_event(move_event, self)
						undo.commit_event(lose_item_event, self)
						undo.commit_event(unlock_event, self)
						undo.commit_turn()
						if sound:
							sound.play("destroywall")
						return true
				return false
		elif target_tile is Lock:
			if target_tile.locked:
				for inv_item in inventory:
					if inv_item.item.effect.key:
						var lose_item_event = LoseItemEvent.new().setup(inv_item, self)
						var unlock_event = UnlockEvent.new().setup(target_tile)
						unlock_event.coords = coords
						undo.commit_event(move_event, self)
						undo.commit_event(lose_item_event, self)
						undo.commit_event(unlock_event, self)
						undo.commit_turn()
						if sound:
							sound.play("openlock")
						return true
				return false
		elif target_tile is Enemy:
			if target_tile.alive:
				if get_damage(target_tile) >= hp:
					return false
				else:
					var battle_event = BattleEvent.new().setup(target_tile, self)
					battle_event.coords = coords
					undo.commit_event(move_event, self)
					undo.commit_event(battle_event, self)
					undo.commit_turn()
					if sound:
						match target_tile.type:
							Enemy.Type.Fire:
								sound.play("killfire")
							Enemy.Type.Water:
								sound.play("killwater")
							Enemy.Type.Steam:
								sound.play("killsteam")
					return true
		elif target_tile is Item:
			if !target_tile.collected:
				if target_tile.stored:
					var gain_item_event = GainItemEvent.new().setup(target_tile, self)
					var store_event = StoreEvent.new().setup(target_tile)
					store_event.coords = coords
					undo.commit_event(move_event, self)
					undo.commit_event(gain_item_event, self)
					undo.commit_event(store_event, self)
					undo.commit_turn()
				else:
					var collect_event = CollectEvent.new().setup(target_tile)
					collect_event.coords = coords
					undo.commit_event(move_event, self)
					undo.commit_event(collect_event, self)
					undo.commit_turn()
				if sound:
					if target_tile.effect.mag < 0:
						sound.play("potionfire")
					elif target_tile.effect.mag > 0:
						sound.play("potionwater")
					elif target_tile.effect.steam:
						sound.play("potionsteam")
					elif target_tile.effect.healing:
						sound.play("potionhp")
					elif target_tile.effect.key:
						sound.play("keypickup")
					elif (
						target_tile.effect.armor or
						target_tile.effect.shield or
						target_tile.effect.pickaxe
					):
						sound.play("genericpickup")
					else:
						sound.play("mysteriouspickup")
				return true
		elif target_tile is Gate:
			if !target_tile.is_passable(mag):
				return false
		# default
		if coords != player.coords:
			undo.commit_event(move_event, self)
			if sound:
				sound.play("movecycle")
			return true
	return false

func use_item(idx: int, undo: Undo, sound: SoundServer = null) -> bool:
	if inventory.size() <= idx:
		return false
	var lose_item_event = LoseItemEvent.new().setup(inventory[idx], self)
	var use_event = UseItemEvent.new().setup(inventory[idx].item, self)
	undo.commit_event(lose_item_event, self)
	undo.commit_event(use_event, self)
	undo.commit_turn()
	if sound:
		sound.play("useitem")
	return true

class_name Main extends Control

const INVENTORY_SLOT = preload("uid://d3qg4odusrnnb")
const SOUND_BUTTON_MUTED = preload("uid://dgemm8310pjis")
const SOUND_BUTTON_UNMUTED = preload("uid://cpenobkdaquey")

@export var cheats_enabled := true

var game := Game.new()
var undo := Undo.new()
@onready var sound = %SoundServer
@onready var playback: AudioStreamPlaybackInteractive = %MusicStream.get_stream_playback()

# user preferences
var prefs := UserPreferences.new()

var game_interactable := false

var selected_save_slot := 0
@export var clear_confirmation_timer: Timer

var key_repeat_held := false
var key_repeat_action: String
var key_repeat_count: int
var key_repeat_due: int

func _on_tile_layer_child_entered_tree(tile: TileActor):
	if !tile.data:
		return
	tile.data = tile.data.duplicate()
	
	var tile_coords = %TileLayer.local_to_map(%TileLayer.to_local(tile.global_position))
	tile.data.coords = tile_coords
	tile.data.id = tile_coords.x * 100 + tile_coords.y
	game.add_tile(tile.data)

func _on_tile_layer_child_exiting_tree(tile: TileActor):
	game.remove_tile(tile.data)

func _on_stack_layer_child_entered_tree(stack):
	var tile_coords = %StackLayer.local_to_map(%StackLayer.to_local(stack.global_position))
	var tile = game.get_tile_at(tile_coords)
	if tile:
		tile.stacks = stack.stacks
	stack.hide()
	stack.queue_free()

func _ready():
	undo.reset(game)
	clear_confirmation_timer.timeout.connect(_reset_clear_confirmation)
	game.setup_astar()
	
	load_user_prefs()
	if prefs.tutorial_seen:
		%ColorRect.hide()
		game_interactable = true
	update_volume()
	
	# tile layers need a frame to process
	await get_tree().process_frame
	preview_game = game.duplicate_deep()
	preview_game.setup_astar()
	update_save_slot_preview()

func _process(_dt):
	handle_mouse_click()
	handle_mouse_hover()
	handle_cheat_inputs()
	update_volume()
	
	var clip_index: int
	if game.mag >= game.steam + 5:
		clip_index = 2
	elif game.mag <= -game.steam - 5:
		clip_index = 1
	else:
		clip_index = 0
	
	if playback.get_current_clip_index() != clip_index:
		playback.switch_to_clip(clip_index)
	
	if Input.is_action_just_pressed("reset") and game_interactable:
		var success = undo.reset(game)
		update_visuals()
		if sound:
			if success:
				sound.play("restart")
			else:
				sound.play("nuhuh")
	
	if Input.is_action_just_pressed("undo"):
		key_repeat_held = true
		key_repeat_action = "undo"
		key_repeat_count = 0
		key_repeat_due = Time.get_ticks_msec()
	if Input.is_action_just_released("undo"):
		if key_repeat_action == "undo":
			key_repeat_held = false
	if Input.is_action_just_pressed("redo"):
		key_repeat_held = true
		key_repeat_action = "redo"
		key_repeat_count = 0
		key_repeat_due = Time.get_ticks_msec()
	if Input.is_action_just_released("redo"):
		if key_repeat_action == "redo":
			key_repeat_held = false
	if key_repeat_held and Time.get_ticks_msec() >= key_repeat_due:
		match key_repeat_action:
			"undo":
				try_undo()
			"redo":
				try_redo()
		key_repeat_count += 1
		key_repeat_due = Time.get_ticks_msec() + key_repeat_interval()
	
	if Input.is_action_just_pressed("master_up"):
		if prefs.master_vol >= 200:
			sound.play("nuhuh")
		else:
			prefs.master_vol = prefs.master_vol + 10
			sound.play("uiinteract")
			save_user_prefs()
	if Input.is_action_just_pressed("master_down"):
		if prefs.master_vol <= 0:
			sound.play("nuhuh")
		else:
			prefs.master_vol = prefs.master_vol - 10
			sound.play("uiinteract")
			save_user_prefs()
	if Input.is_action_just_pressed("music_up"):
		if prefs.music_vol >= 200:
			sound.play("nuhuh")
		else:
			prefs.music_vol = prefs.music_vol + 10
			sound.play("uiinteract")
			save_user_prefs()
	if Input.is_action_just_pressed("music_down"):
		if prefs.music_vol <= 0:
			sound.play("nuhuh")
		else:
			prefs.music_vol = prefs.music_vol - 10
			sound.play("uiinteract")
			save_user_prefs()
	if Input.is_action_just_pressed("sfx_up"):
		if prefs.sfx_vol >= 200:
			sound.play("nuhuh")
		else:
			prefs.sfx_vol = prefs.sfx_vol + 10
			sound.play("uiinteract")
			save_user_prefs()
	if Input.is_action_just_pressed("sfx_down"):
		if prefs.sfx_vol <= 0:
			sound.play("nuhuh")
		else:
			prefs.sfx_vol = prefs.sfx_vol - 10
			sound.play("uiinteract")
			save_user_prefs()
	
	%HPLabel.text = "HP: %d" % game.hp
	if game.mag > 0:
		%MAGLabel.text = "%d [outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color]" % abs(game.mag)
	elif game.mag == 0:
		%MAGLabel.text = "%d" % abs(game.mag)
	else:
		%MAGLabel.text = "%d [color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color]" % abs(game.mag)
	%SteamLabel.text = "+ %d [shake rate=10.0 level=3 connected=0]Steam[/shake]" % game.steam
	%DEFLabel.text = "DEF: %d" % game.defense

var key_repeat_interval_max = 500.0
var key_repeat_interval_min = 50.0
func key_repeat_interval():
	return (key_repeat_interval_max - key_repeat_interval_min) / pow(key_repeat_count, 0.7) + key_repeat_interval_min

func try_undo():
	if !game_interactable:
		return
	var success = undo.undo(game)
	update_visuals()
	if sound:
		if success:
			sound.play("undo")
		else:
			sound.play("nuhuh")

func try_redo():
	if !game_interactable:
		return
	var success = undo.redo(game)
	update_visuals()
	if sound:
		if success:
			sound.play("redo")
		else:
			sound.play("nuhuh")

func save_game():
	var save := undo.get_save(game)
	ResourceSaver.save(save, "user://save%d.tres" % [selected_save_slot + 1])
	update_save_slot_preview(game)
	sound.play("savestate")

func load_game():
	if !FileAccess.file_exists("user://save%d.tres" % [selected_save_slot + 1]):
		sound.play("nuhuh")
		return
	var save: Save = ResourceLoader.load("user://save%d.tres" % [selected_save_slot + 1], "", ResourceLoader.CACHE_MODE_IGNORE)
	if !save:
		sound.play("nuhuh")
		return
	
	undo.clear(game)
	undo.load_save(save, game)
	update_visuals()
	sound.play("loadstate")

var clear_confirmation := 0
func clear_save():
	if !FileAccess.file_exists("user://save%d.tres" % [selected_save_slot + 1]):
		sound.play("nuhuh")
		return
	if clear_confirmation < 2:
		match clear_confirmation:
			0:
				%ClearButton.text = "Sure?"
			1:
				%ClearButton.text = "Really?"
		clear_confirmation += 1
		clear_confirmation_timer.start()
		sound.play("uiinteract")
		return
	
	DirAccess.remove_absolute("user://save%d.tres" % [selected_save_slot + 1])
	_update_save_slot_preview(null)
	sound.play("erased")
	
	clear_confirmation_timer.stop()
	clear_confirmation_timer.timeout.emit()

func _reset_clear_confirmation():
	clear_confirmation = 0
	%ClearButton.text = "Clear"

func export_save():
	if !FileAccess.file_exists("user://save%d.tres" % [selected_save_slot + 1]):
		sound.play("nuhuh")
		return
	var save: Save = ResourceLoader.load("user://save%d.tres" % [selected_save_slot + 1], "", ResourceLoader.CACHE_MODE_IGNORE)
	if !save:
		sound.play("nuhuh")
		return
	
	var d: Dictionary
	d.cur_turn = save.cur_turn
	d.undo_stack = save.stack
	d.redo_stack = save.undo_stack
	var s = JSON.stringify(d)
	DisplayServer.clipboard_set(s)
	sound.play("loadstate")

func import_save():
	var save := Save.new()
	var json = JSON.new()
	if json.parse(DisplayServer.clipboard_get()) != OK:
		sound.play("nuhuh")
		return
	var d = json.data
	if d is not Dictionary:
		sound.play("nuhuh")
		return
	if "cur_turn" not in d:
		sound.play("nuhuh")
		return
	if "undo_stack" not in d:
		sound.play("nuhuh")
		return
	if "redo_stack" not in d:
		sound.play("nuhuh")
		return
	save.cur_turn.assign(d.cur_turn)
	save.stack.assign(d.undo_stack)
	save.undo_stack.assign(d.redo_stack)
	ResourceSaver.save(save, "user://save%d.tres" % [selected_save_slot + 1])
	update_save_slot_preview()
	sound.play("savestate")

func save_user_prefs():
	ResourceSaver.save(prefs, "user://prefs.tres")

func load_user_prefs():
	if FileAccess.file_exists("user://prefs.tres"):
		prefs = ResourceLoader.load("user://prefs.tres")

func _on_prev_save_button_pressed():
	selected_save_slot = posmod(selected_save_slot - 1, 16)
	update_save_slot_preview()
	sound.play("uiinteract")
	
	clear_confirmation_timer.stop()
	clear_confirmation_timer.timeout.emit()

func _on_next_save_button_pressed():
	selected_save_slot = (selected_save_slot + 1) % 16
	update_save_slot_preview()
	sound.play("uiinteract")
	
	clear_confirmation_timer.stop()
	clear_confirmation_timer.timeout.emit()

var preview_save: Save
var preview_game: Game
var preview_undo := Undo.new()
func update_save_slot_preview(_game: Game = null):
	preview_undo.clear(preview_game)
	
	if !_game:
		if !FileAccess.file_exists("user://save%d.tres" % [selected_save_slot + 1]):
			_update_save_slot_preview(null)
			return
		var loaded = ResourceLoader.load("user://save%d.tres" % [selected_save_slot + 1], "", ResourceLoader.CACHE_MODE_IGNORE)
		if !loaded or loaded is not Save:
			_update_save_slot_preview(null)
			return
		preview_save = loaded
		
		if preview_save.hp:
			_game = Game.new()
			_game.hp = preview_save.hp
			_game.mag = preview_save.mag
			_game.steam = preview_save.steam
		else:
			preview_undo.load_save(preview_save, preview_game)
			_game = preview_game
	
	_update_save_slot_preview(_game)

func _update_save_slot_preview(_game: Game, error := ""):
	%SaveNameLabel.text = "Save Slot %d" % [selected_save_slot + 1]
	
	if error:
		%SaveInfoLabel.text = error
		return
	
	if _game == null:
		%SaveInfoLabel.text = "No Data"
		return
	
	%SaveInfoLabel.text = (
		"HP: %d\n" +
		"MAG: %d%s + %d [shake rate=10.0 level=3 connected=0]Steam[/shake]"
	) % [
		_game.hp,
		abs(_game.mag),
		" [outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color]" if _game.mag > 0
		else " [color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color]" if _game.mag < 0
		else "",
		_game.steam
	]

func handle_mouse_click():
	
	var mouse_coord: Vector2i = %TileLayer.local_to_map(%TileLayer.to_local(get_global_mouse_position()))
	if Input.is_action_just_pressed("mouse_click") and game_interactable:
		game.do_move(mouse_coord, undo, sound)
		update_visuals()
	if Input.is_action_just_pressed("ui_up"):
		game.do_move(game.player.coords + Vector2i.UP, undo, sound)
		update_visuals()
	if Input.is_action_just_pressed("ui_right"):
		game.do_move(game.player.coords + Vector2i.RIGHT, undo, sound)
		update_visuals()
	if Input.is_action_just_pressed("ui_down"):
		game.do_move(game.player.coords + Vector2i.DOWN, undo, sound)
		update_visuals()
	if Input.is_action_just_pressed("ui_left"):
		game.do_move(game.player.coords + Vector2i.LEFT, undo, sound)
		update_visuals()
	if Input.is_action_just_pressed("up"):
		game.do_move(game.player.coords + Vector2i.UP, undo, sound)
		update_visuals()
	if Input.is_action_just_pressed("right"):
		game.do_move(game.player.coords + Vector2i.RIGHT, undo, sound)
		update_visuals()
	if Input.is_action_just_pressed("down"):
		game.do_move(game.player.coords + Vector2i.DOWN, undo, sound)
		update_visuals()
	if Input.is_action_just_pressed("left"):
		game.do_move(game.player.coords + Vector2i.LEFT, undo, sound)
		update_visuals()

func _on_inventory_slot_pressed(slot: InventorySlot):
	if !game_interactable:
		return
	if slot.inv_item.item.passive:
		return
	game.use_item(game.inventory.find(slot.inv_item), undo, sound)
	
	inventory_hover = null
	update_visuals()

var ui_hover := 0
func _on_undo_button_mouse_entered():
	ui_hover = 1
func _on_redo_button_mouse_entered():
	ui_hover = 2
func _on_restart_button_mouse_entered():
	ui_hover = 3
func _on_hp_label_mouse_entered():
	ui_hover = 4
func _on_mag_mouse_entered():
	ui_hover = 5
func _on_def_label_mouse_entered():
	ui_hover = 6
func _on_items_mouse_entered():
	ui_hover = 7
func _on_mute_button_mouse_entered():
	ui_hover = 8
func _on_button_mouse_exited():
	ui_hover = 0

var inventory_hover: InventorySlot = null
func _on_inventory_slot_mouse_entered(slot: InventorySlot):
	inventory_hover = slot
func _on_inventory_slot_mouse_exited():
	inventory_hover = null

var hover_path: Array[Vector2i]
func handle_mouse_hover():
	hide_path_arrow()
	hide_cursor()
	var mouse_coord: Vector2i = %TileLayer.local_to_map(%TileLayer.to_local(get_global_mouse_position()))
	var out_of_bounds := mouse_coord.x < 0 or mouse_coord.y < 0 or mouse_coord.x >= game.level_size.x or mouse_coord.y >= game.level_size.y
	var hover_tile := game.get_tile_at(mouse_coord)
	
	game.update_astar()
	hover_path.assign([] if out_of_bounds else game.pathfind(game.player.coords, mouse_coord))
	
	# show coordinates if in-bounds
	if !out_of_bounds and game_interactable:
		%PreviewCoord.show()
		%PreviewCoord.text = "(%d, %d)" % [mouse_coord.x, mouse_coord.y]
	else:
		%PreviewCoord.hide()
	
	# default description visuals
	var preview_sprite: Texture2D = null
	var preview_name := ""
	var preview_desc := get_controls_string()
	
	if ui_hover > 0:
		match ui_hover:
			1:
				preview_name = "Undo"
				preview_desc = undo.get_stack_string()
			2:
				preview_name = "Redo"
				preview_desc = undo.get_stack_string()
			3:
				preview_name = "Restart"
				preview_desc = undo.get_stack_string()
			4:
				preview_name = "HP"
				preview_desc = (
					"Your current health. Don't let it reach 0!\n" + 
					"You lose health by battling enemies.\n" +
					"When battling an enemy, you take turns landing [color=#19011a][outline_color=#ffebd8][outline_size=5]hits[/outline_size][/outline_color][/color] on each other until one of you dies. You always take the first turn."
				)
			5:
				preview_name = "MAG"
				preview_desc = (
					"Your current magic levels.\n" +
					"There are three types of MAG:\n" +
					"[outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color]: Adds to your damage on [color=#19011a][outline_color=#ffebd8][outline_size=5]hits[/outline_size][/outline_color][/color] against [color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color] enemies. Cancels out with [color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color] MAG.\n" +
					"[color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color]: Adds to your damage on [color=#19011a][outline_color=#ffebd8][outline_size=5]hits[/outline_size][/outline_color][/color] against [outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color] enemies. Cancels out with [outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color] MAG.\n" +
					"[shake rate=10.0 level=3 connected=0]Steam[/shake]: Adds to your damage on [color=#19011a][outline_color=#ffebd8][outline_size=5]hits[/outline_size][/outline_color][/color] against [u]all[/u] enemies."
				)
			6:
				preview_name = "DEF"
				preview_desc = "Your current defense.\nDefense subtracts damage each time an enemy [color=#19011a][outline_color=#ffebd8][outline_size=5]hits[/outline_size][/outline_color][/color] you."
			7:
				preview_name = "ITEMS"
				preview_desc = "Your current held items.\nSome items do something as soon as you [u]collect[/u] them. Some provide a constant effect while you're [u]holding[/u] them. Some held items have to be [u]used[/u] by clicking on them.\nHover your cursor over various items around the level to learn what they do!"
			8:
				preview_name = "Sound"
				preview_desc = (
					"Click to toggle mute or use keys to adjust volume:\n" +
					"Master: %d%s (U/J)\n" +
					"Music: %d%s (I/K)\n" +
					"SFX: %d%s (O/L)"
				) % [
					prefs.master_vol if !prefs.muted else 0,
					"%",
					prefs.music_vol,
					"%",
					prefs.sfx_vol,
					"%",
				]
	elif inventory_hover:
		preview_sprite = inventory_hover.tile.get_node("Sprite2D").texture
		preview_name = inventory_hover.inv_item.item.tile_name
		preview_desc = get_item_description(inventory_hover.tile.data)
		if !inventory_hover.inv_item.item.passive:
			show_cursor_at(inventory_hover.get_node("Tile").global_position)
	elif hover_tile and !out_of_bounds and game_interactable:
		if hover_tile is Player:
			preview_sprite = hover_tile.actor.get_node("Sprite2D").texture
			preview_name = hover_tile.tile_name
			preview_desc = (
				"It's you!\n" +
				"Battle enemies with your MAG and reach the goal to win."
			)
		elif hover_tile is Wall and !hover_tile.destroyed:
			preview_sprite = hover_tile.actor.get_node("Sprite2D").texture
			preview_name = hover_tile.tile_name
			preview_desc = "Impassable."
			if hover_path:
				for inv_item in game.inventory:
					if inv_item.item.effect.pickaxe:
						show_path_arrow(hover_path, false)
						show_cursor(hover_path[-1])
						break
		elif hover_tile is Lock and hover_tile.locked:
			preview_sprite = hover_tile.actor.get_node("Sprite2D").texture
			preview_name = hover_tile.tile_name
			preview_desc = "Impassable. Open with a Key."
			if hover_path:
				for inv_item in game.inventory:
					if inv_item.item.effect.key:
						show_path_arrow(hover_path, false)
						show_cursor(hover_path[-1])
						break
		elif hover_tile is Enemy and hover_tile.alive:
			preview_sprite = hover_tile.actor.get_node("Sprite2D").texture
			preview_name = hover_tile.tile_name
			preview_desc = (
				"HP: %d\n" +
				"ATK: %d\n" +
				#"STEAM: %d\n" +
				"Your hits deal %d damage, defeating it in %d %s.\n" +
				"You will take [color=#19011a][outline_color=#ffebd8][outline_size=4]%d[/outline_size][/outline_color][/color] damage over [color=#19011a][outline_color=#ffebd8][outline_size=4]%d[/outline_size][/outline_color][/color] %s when battling it.\n" +
				"%s"
			) % [
				hover_tile.get_hp(),
				hover_tile.get_attack(),
				#hover_tile.get_steam(),
				game.get_attack(hover_tile),
				game.get_turns(hover_tile) + 1,
				"hit" if game.get_turns(hover_tile) == 0 else "hits",
				game.get_damage(hover_tile),
				game.get_shielded_turns(hover_tile),
				"hit" if game.get_turns(hover_tile) == 1 else "hits",
				game.get_help_string(hover_tile)
			]
			if hover_path:
				show_path_arrow(hover_path, false)
				show_cursor(hover_path[-1])
		elif hover_tile is Item and !hover_tile.collected:
			preview_sprite = hover_tile.actor.get_node("Sprite2D").texture
			preview_name = hover_tile.tile_name
			preview_desc = get_item_description(hover_tile)
			if hover_path:
				show_path_arrow(hover_path, false)
				show_cursor(hover_path[-1])
		elif hover_tile is Gate:
			preview_sprite = hover_tile.actor.get_node("Sprite2D").texture
			preview_name = hover_tile.tile_name
			if hover_tile.is_water:
				preview_desc = "You can only pass through if you have [outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color] MAG."
			else:
				preview_desc = "You can only pass through if you have [color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color] MAG."
			if hover_tile.is_passable(game.mag):
				show_path_arrow(hover_path, true)
		elif hover_tile is Goal:
			preview_sprite = hover_tile.actor.get_node("Sprite2D").texture
			preview_name = hover_tile.tile_name
			preview_desc = "Stand on this tile to win!"
			show_path_arrow(hover_path, true)
		else:
			if hover_path:
				show_path_arrow(hover_path, true)
	else:
		if hover_path:
			show_path_arrow(hover_path, true)
	
	if Input.is_action_pressed("control"):
		preview_desc = undo.get_stack_string()
		
	if game.player and game.goal and game.player.coords == game.goal.coords:
		preview_desc = game.get_win_string()
	
	if %PreviewSprite.texture != preview_sprite:
		%PreviewSprite.texture = preview_sprite
	if %PreviewName.text != preview_name:
		%PreviewName.text = preview_name
	if %PreviewDesc.text != preview_desc:
		%PreviewDesc.text = preview_desc

func handle_cheat_inputs():
	if !cheats_enabled:
		return
	var delta = 0
	if Input.is_action_just_pressed("cheat_add"):
		delta += 1
	if Input.is_action_just_pressed("cheat_subtract"):
		delta -= 1
	if Input.is_action_pressed("cheat_mag"):
		game.mag += delta
	if Input.is_action_pressed("cheat_steam"):
		game.steam += delta
	if Input.is_action_pressed("cheat_hp"):
		game.hp += delta * 10
	if Input.is_action_pressed("cheat_defense"):
		game.defense += delta

# force all tile visuals to match internal state
func update_visuals():
	for id in game.tiles:
		var tile := game.tiles[id]
		tile.actor.global_position = %TileLayer.to_global(%TileLayer.map_to_local(tile.coords))
	
	var tracked_items: Array[InvItem] = []
	for slot: InventorySlot in %InventorySlotContainer.get_children():
		if slot.inv_item not in game.inventory:
			slot.queue_free()
		else:
			tracked_items.append(slot.inv_item)
			slot.tile.data.stacks = slot.inv_item.stacks
	for inv_item in game.inventory:
		if inv_item not in tracked_items:
			var slot: InventorySlot = INVENTORY_SLOT.instantiate()
			slot.mouse_entered.connect(_on_inventory_slot_mouse_entered.bind(slot))
			slot.mouse_exited.connect(_on_inventory_slot_mouse_exited)
			slot.pressed.connect(_on_inventory_slot_pressed.bind(slot))
			%InventorySlotContainer.add_child(slot)
			slot.inv_item = inv_item
			slot.tile.data = inv_item.item.duplicate()
			slot.tile.data.stacks = inv_item.stacks
			slot.tile.get_node("Sprite2D").texture = inv_item.item.actor.get_node("Sprite2D").texture
	
	# sort by order
	var sorted_nodes = %InventorySlotContainer.get_children()
	sorted_nodes.sort_custom(
		func(a: InventorySlot, b: InventorySlot):
			return game.inventory.find(a.inv_item) > game.inventory.find(b.inv_item)
	)
	for c in sorted_nodes:
		%InventorySlotContainer.move_child(c, 0)

func update_volume():
	var master_vol = prefs.master_vol if !prefs.muted else 0
	if master_vol/100.0 != AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master")):
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), master_vol/100.0)
	if prefs.music_vol/100.0 != AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music")):
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"), prefs.music_vol/100.0)
	if prefs.sfx_vol/100.0 != AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("SFX")):
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), prefs.sfx_vol/100.0)
	if prefs.muted:
		if %MuteButton.icon != SOUND_BUTTON_MUTED:
			%MuteButton.icon = SOUND_BUTTON_MUTED
	if !prefs.muted:
		if %MuteButton.icon != SOUND_BUTTON_UNMUTED:
			%MuteButton.icon = SOUND_BUTTON_UNMUTED

func hide_path_arrow():
	%Arrow.hide()
func show_path_arrow(path: Array[Vector2i], include_end: bool):
	var _path = path if include_end else path.slice(0,-1)
	if _path.size() < 2:
		return
	%Arrow.show()
	%Line2D.clear_points()
	for coord in _path:
		%Line2D.add_point(%TileLayer.map_to_local(coord))
	%Arrowhead.position = %TileLayer.map_to_local(_path[-1])
	%Arrowhead.rotation = Vector2(path[-1] - path[-2]).angle()

func hide_cursor():
	%TileCursor.hide()
func show_cursor(coord: Vector2i):
	%TileCursor.show()
	%TileCursor.position = %TileLayer.map_to_local(coord)
func show_cursor_at(global_pos: Vector2):
	%TileCursor.show()
	%TileCursor.global_position = global_pos

func _on_undo_button_pressed():
	undo.undo(game)
	update_visuals()

func _on_redo_button_pressed():
	undo.redo(game)
	update_visuals()

func _on_restart_button_pressed():
	undo.reset(game)
	update_visuals()

func get_controls_string() -> String:
	return (
		"Hover your cursor over things to see a helpful tooltip appear here!\n\n" +
		"Click/WASD: Move\n" +
		"Click: Use Item\n" +
		"Z: Undo\n" +
		"Y: Redo\n" +
		"R: Restart\n" +
		"Ctrl: Show Move History"
	)

func get_item_description(item: Item) -> String:
	var description_items: Array[String] = []
	if item.effect.healing != 0:
		description_items.append("HP +%d" % [item.effect.healing * item.stacks])
	if item.effect.steam != 0:
		description_items.append("[shake rate=10.0 level=3 connected=0]Steam[/shake] +%d" % [item.effect.steam * item.stacks])
	if item.effect.mag != 0:
		if item.effect.mag > 0:
			description_items.append("[outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color] +%d" % [item.effect.mag * item.stacks])
		else:
			description_items.append("[color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color] +%d" % [-item.effect.mag * item.stacks])
	if item.effect.defense != 0:
		description_items.append("DEF +%d" % [item.effect.defense * item.stacks])
	if item.effect.key:
		description_items.append("Spend to open a Lock.")
	if item.effect.armor:
		description_items.append("Subtract %d damage each time an enemy [color=#19011a][outline_color=#ffebd8][outline_size=5]hits[/outline_size][/outline_color][/color] you." % [item.effect.armor * item.stacks])
	if item.effect.shield:
		description_items.append("Prevent all damage from the first %s each enemy lands on you." % (
			"[color=#19011a][outline_color=#ffebd8][outline_size=5]hit[/outline_size][/outline_color][/color]"
			if item.effect.shield * item.stacks == 1
			else "%d [color=#19011a][outline_color=#ffebd8][outline_size=5]hits[/outline_size][/outline_color][/color]" % [item.effect.shield * item.stacks])
		)
	if item.effect.pickaxe:
		description_items.append("Spend to destroy a Wall.")
	if item.effect.double_scroll:
		description_items.append("Double your current [outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color] / [color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color] MAG.")
	if item.effect.swap_scroll:
		description_items.append("Swap your current [outline_color=#4f67ff][outline_size=4]Water[/outline_size][/outline_color] MAG for [color=#19011a][outline_color=#ff7f00][outline_size=4]Fire[/outline_size][/outline_color][/color] MAG, or vice-versa.")
	if item.effect.steam_orb:
		description_items.append("[shake rate=10.0 level=3 connected=0]Steam[/shake] gain is doubled.")
	if item.effect.lantern:
		description_items.append("When you defeat a Sprite enemy, you gain 10 MAG of the same type.")
	if description_items:
		if item.stored:
			if item.passive:
				description_items.insert(0, "While Held:")
			else:
				description_items.insert(0, "On Use:")
		else:
			description_items.insert(0, "On Pickup:")
	return "\n".join(description_items)


func _on_export_button_pressed():
	if !FileAccess.file_exists("user://save%d.tres" % [selected_save_slot + 1]):
		sound.play("nuhuh")
		return
	var save: Save = ResourceLoader.load("user://save%d.tres" % [selected_save_slot + 1], "", ResourceLoader.CACHE_MODE_IGNORE)
	if !save:
		sound.play("nuhuh")
		return
	
	var d: Dictionary
	d.cur_turn = save.cur_turn
	d.undo_stack = save.stack
	d.redo_stack = save.undo_stack
	var s = JSON.stringify(d)
	%LineEdit.text = s
	sound.play("loadstate")

func _on_tutorial_button_pressed():
	%ColorRect.hide()
	game_interactable = true
	sound.play("uiinteract")
	
	prefs.tutorial_seen = true
	save_user_prefs()

func _on_mute_button_pressed():
	prefs.muted = !prefs.muted
	save_user_prefs()

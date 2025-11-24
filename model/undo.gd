class_name Undo extends Resource

var cur_turn := Turn.new()
var stack: Array[Turn]
var undo_stack: Array[Turn]

func commit_event(event: Event, game: Game) -> bool:
	var success = event.do(game)
	cur_turn.events.append(event)
	return success
func commit_turn():
	stack.append(cur_turn)
	cur_turn = Turn.new()
	undo_stack = []
func undo(game: Game) -> bool:
	if stack.size() == 1:
		return false
	cur_turn.undo(game)
	cur_turn = Turn.new()
	if stack.is_empty():
		return false
	var turn = stack.pop_back()
	turn.undo(game)
	undo_stack.append(turn)
	return true
func redo(game: Game) -> bool:
	cur_turn.undo(game)
	cur_turn = Turn.new()
	if undo_stack.is_empty():
		return false
	var turn = undo_stack.pop_back()
	turn.do(game)
	stack.append(turn)
	return true
func reset(game: Game) -> bool:
	if stack and stack[-1].events[-1] is RestartEvent:
		return false
	
	var size = stack.size()
	# iterate all events in reverse
	for i in size:
		var turn := stack[size - i - 1]
		var turn_size = turn.events.size()
		for j in turn_size:
			commit_event(turn.events[turn_size - j - 1].reversed(), game)
	commit_event(RestartEvent.new(), game)
	commit_turn()
	return true
func clear(game: Game):
	reset(game)
	cur_turn = Turn.new()
	stack.clear()
	undo_stack.clear()

func get_save() -> Save:
	var save := Save.new()
	for event in cur_turn.events:
		save.cur_turn.append(serialize_event(event))
	for turn in stack:
		save.stack.append(serialize_event(turn.events[-1]))
	for turn in undo_stack:
		save.undo_stack.append(serialize_event(turn.events[-1]))
		save.undo_stack.reverse()
	return save

func load_save(save: Save, game: Game):
	for action in save.stack:
		if !deserialize_event(action, game):
			return
	var num = 0
	for action in save.undo_stack:
		if !deserialize_event(action, game):
			break
		num += 1
	for i in num:
		undo(game)
	for action in save.cur_turn:
		if !deserialize_event(action, game):
			return

func serialize_event(e: Event) -> String:
	if e is RestartEvent:
		return "r"
	if e is UseItemEvent:
		return "i" + str(e.idx)
	return "c" + str(e.coords.x) + "," + str(e.coords.y)
func deserialize_event(s: String, game: Game) -> bool:
	if s == "r":
		reset(game)
		return true
	if s.begins_with("i"):
		var idx = int(s.substr(1))
		if game.inventory.size() <= idx:
			return false
		return game.use_item(idx, self)
	if s.begins_with("c"):
		var coords = s.substr(1).split(",")
		return game.do_move(Vector2i(int(coords[0]), int(coords[1])), self)
	return false

func get_stack_string() -> String:
	var turn_strings = ["Move History:"]
	var preferred_redo = 3
	var preferred_undo = 7
	var max_size = preferred_redo + preferred_undo
	var num_redo
	var num_undo
	if stack.size() >= preferred_undo and undo_stack.size() >= preferred_redo:
		num_redo = preferred_redo
		num_undo = preferred_undo
	elif stack.size() >= preferred_undo:
		num_redo = undo_stack.size()
		num_undo = min(stack.size(), max_size-undo_stack.size())
	elif undo_stack.size() >= preferred_redo:
		num_redo = min(undo_stack.size(), max_size-stack.size())
		num_undo = stack.size()
	else:
		num_redo = undo_stack.size()
		num_undo = stack.size()
	
	for i in num_redo:
		if turn_strings.size() == max_size + 1:
			break
		var idx = undo_stack.size() - min(undo_stack.size(), num_redo) + i
		turn_strings.append(
			"(%d): " % [stack.size() + undo_stack.size() - idx - 1] +
			undo_stack[idx].as_string()
		)
	for j in num_undo:
		if turn_strings.size() == max_size + 1:
			break
		turn_strings.append(
			("*" if j == 0 else "") +
			"(%d): " % [stack.size() - j - 1] +
			stack[stack.size() - j - 1].as_string()
		)
	return "\n".join(turn_strings)

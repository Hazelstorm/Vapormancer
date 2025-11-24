class_name Turn extends Resource

@export var events: Array[Event]

func do(game: Game):
	for event in events:
		event.do(game)
func undo(game: Game):
	# iterate in reverse
	for i in events.size():
		events[events.size() - i - 1].undo(game)
func as_string() -> String:
	if !events:
		return ""
	return events[-1].as_string()

class_name RestartEvent extends Event

func _do(_game: Game):
	return true
func _undo(_game: Game):
	return true
func as_string() -> String:
	return "Restart"

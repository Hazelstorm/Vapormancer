class_name UnlockEvent extends Event

@export var lock: Tile

func setup(_lock: Tile):
	lock = _lock
	return self

func _do(game: Game) -> bool:
	if !lock:
		print("ERROR UnlockEvent @ (%d,%d) failed. Reason: null lock" % [coords.x, coords.y])
		return false
	if lock is not Lock and lock is not Wall:
		print("ERROR UnlockEvent @ (%d,%d) failed. Reason: lock is not Lock or Wall" % [coords.x, coords.y])
		return false
	if lock.actor:
		lock.actor.hide()
	if lock is Lock:
		lock.locked = false
	if lock is Wall:
		lock.destroyed = true
	return true
	
func _undo(game: Game) -> bool:
	if !lock:
		print("ERROR Undo UnlockEvent @ (%d,%d) failed. Reason: null lock" % [coords.x, coords.y])
		return false
	if lock is not Lock and lock is not Wall:
		print("ERROR Undo UnlockEvent @ (%d,%d) failed. Reason: lock is not Lock or Wall" % [coords.x, coords.y])
		return false
	if lock.actor:
		lock.actor.show()
	if lock is Lock:
		lock.locked = true
	if lock is Wall:
		lock.destroyed = false
	return true
	
func as_string() -> String:
	return "Use key"

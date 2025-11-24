class_name Gate extends Tile

@export var is_water: bool

func is_passable(mag: int):
	if is_water:
		return mag > 0
	return mag < 0

class_name Item extends Tile

@export var effect: ItemEffect
@export var stored := false # stored in inventory to give a passive/active effect
@export var passive := false
@export_storage var collected := false

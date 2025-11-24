class_name TileActor extends Node2D

@export var data: Tile:
	set(value):
		if data:
			data.actor = null
			data.stacks_changed.disconnect(_on_stacks_changed)
		data = value
		if data:
			data.actor = self
			data.stacks_changed.connect(_on_stacks_changed)

func _on_stacks_changed():
	%Label.visible = data.stacks != 1
	%Label.text = "x%d" % data.stacks

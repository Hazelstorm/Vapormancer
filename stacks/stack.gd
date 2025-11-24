@tool
class_name Stack extends Node2D

@export var stacks := 1:
	set(value):
		stacks = value
		%Label.text = "x%d" % stacks

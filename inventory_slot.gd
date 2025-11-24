class_name InventorySlot extends Control

signal pressed

var inv_item: InvItem
@export var tile: TileActor

func _on_button_pressed():
	pressed.emit()

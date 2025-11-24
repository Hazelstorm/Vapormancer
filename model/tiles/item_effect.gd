class_name ItemEffect extends Resource

@export var healing := 0
@export var mag := 0
@export var defense := 0
@export var steam := 0
@export var key := false
@export var shield := 0
@export var armor := 0
@export var pickaxe := false
@export var double_scroll := false
@export var swap_scroll := false
@export var steam_orb := false
@export var lantern := false

func serialize() -> Dictionary:
	var d: Dictionary
	for property in get_script().get_script_property_list():
		if !property:
			continue
		d[property.name] = get(property.name)
	return d

func deserialize(d: Dictionary) -> ItemEffect:
	for property_name in d:
		set(property_name, d[property_name])
	return self

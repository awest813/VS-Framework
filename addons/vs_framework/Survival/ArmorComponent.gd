## ArmorComponent — wearable item that absorbs incoming damage.
##
## Attach to the player and wire into your damage pipeline:
## call absorb(raw_damage) which returns the reduced damage amount.
## The component degrades with each hit using an ItemCondition child node.
extends Node
class_name ArmorComponent

signal armor_changed(absorption : float)

## Base absorption fraction (0–1). E.g. 0.4 = absorbs 40% of damage.
@export_range(0.0, 1.0) var base_absorption : float = 0.4

## ItemCondition child node (optional). If present, condition degrades each hit.
@export_node_path("ItemCondition") var condition_node_path : NodePath = NodePath("")

var _condition : ItemCondition = null
var is_equipped : bool = false


func _ready() -> void:
	if not condition_node_path.is_empty():
		_condition = get_node_or_null(condition_node_path)


## Equip the armor. Sets is_equipped and emits armor_changed.
func equip() -> void:
	is_equipped = true
	armor_changed.emit(get_current_absorption())


## Unequip the armor.
func unequip() -> void:
	is_equipped = false
	armor_changed.emit(0.0)


## Returns damage after armor absorption. Call from damage processing.
## Also applies wear to the ItemCondition if one is attached.
func absorb(raw_damage : float) -> float:
	if not is_equipped:
		return raw_damage

	var absorption : float = get_current_absorption()
	var absorbed : float = raw_damage * absorption
	var final_damage : float = raw_damage - absorbed

	# Apply wear
	if _condition:
		_condition.take_wear()

	return final_damage


## Returns the effective absorption accounting for condition degradation.
func get_current_absorption() -> float:
	if not is_equipped:
		return 0.0
	if _condition and _condition.condition <= _condition.jam_threshold:
		return base_absorption * _condition.degraded_armor_multiplier
	return base_absorption

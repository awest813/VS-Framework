## ItemCondition — attach as a child of any wieldable or armor object to give it durability.
##
## Wire damage_received signal from HitboxComponent (for armor) or your weapon's fire
## function (for weapons) to the take_wear() method.
extends Node
class_name ItemCondition

signal condition_changed(new_condition : float)
signal item_jammed
signal item_broken

## Starting and current condition (0–100).
@export_range(0.0, 100.0) var condition : float = 100.0

## Condition is reduced by this amount per shot / hit.
@export var wear_per_use : float = 1.0

## Below this threshold weapons jam on fire.
@export var jam_threshold : float = 20.0

## Below this threshold the item is considered broken (unusable).
@export var broken_threshold : float = 0.0

## Damage multiplier applied when condition is below jam_threshold.
@export var degraded_damage_multiplier : float = 0.7

## Armor absorption multiplier when below jam_threshold.
@export var degraded_armor_multiplier : float = 0.5

var is_jammed : bool = false
var is_broken : bool = false


## Apply wear from one use. Returns false if the item jammed.
func take_wear(amount : float = -1.0) -> bool:
	var wear : float = amount if amount >= 0 else wear_per_use
	condition = max(condition - wear, broken_threshold)
	condition_changed.emit(condition)

	if condition <= broken_threshold:
		is_broken = true
		item_broken.emit()
		return false

	if condition <= jam_threshold and not is_jammed:
		if randf() < 0.3:
			is_jammed = true
			item_jammed.emit()
			return false

	return true


## Repair the item by a given amount (e.g. from consumables or traders).
func repair(amount : float) -> void:
	is_jammed = false
	is_broken = false
	condition = min(condition + amount, 100.0)
	condition_changed.emit(condition)


## Returns a string label for the HUD tooltip.
func get_condition_label() -> String:
	if is_broken:
		return "BROKEN"
	if condition > 75:
		return "Good"
	if condition > 50:
		return "Worn"
	if condition > jam_threshold:
		return "Damaged"
	return "Critically Damaged"

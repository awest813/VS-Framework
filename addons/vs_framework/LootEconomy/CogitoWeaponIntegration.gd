## CogitoWeaponIntegration — adapter between COGITO wieldables and VS weapon systems.
##
## Add as a child of a CogitoWieldable scene alongside optional ItemCondition and
## WeaponModdingComponent nodes. Weapon scripts call this component when firing to
## apply condition wear, jams, and attachment stat modifiers without replacing
## COGITO's inventory, ammo, or wieldable pipeline.
extends Node
class_name CogitoWeaponIntegration

signal fire_blocked(reason : String)
signal shot_consumed

@export var weapon_mods_path : NodePath
@export var item_condition_path : NodePath
@export var clear_jam_on_reload : bool = true

var weapon_mods : WeaponModdingComponent
var item_condition : ItemCondition
var _components_resolved : bool = false


func _ready() -> void:
	_resolve_components()


func consume_shot() -> bool:
	_resolve_components()
	if item_condition:
		if item_condition.is_broken:
			fire_blocked.emit("broken")
			return false
		if item_condition.is_jammed:
			fire_blocked.emit("jammed")
			return false
		if not item_condition.take_wear():
			fire_blocked.emit("condition")
			return false
	shot_consumed.emit()
	return true


func notify_reload_started() -> void:
	_resolve_components()
	if clear_jam_on_reload and item_condition and item_condition.is_jammed:
		item_condition.clear_jam()


func refresh_components() -> void:
	weapon_mods = null
	item_condition = null
	_components_resolved = false
	_resolve_components()


func get_modified_damage(base_damage : float) -> float:
	_resolve_components()
	var damage : float = base_damage
	if weapon_mods:
		damage += weapon_mods.get_total_damage_modifier()
	if item_condition:
		damage *= item_condition.get_weapon_damage_multiplier()
	return maxf(damage, 0.0)


func get_modified_accuracy(base_accuracy : float = 0.0) -> float:
	_resolve_components()
	if weapon_mods:
		return base_accuracy + weapon_mods.get_total_accuracy_modifier()
	return base_accuracy


func get_modified_recoil(base_recoil : float = 0.0) -> float:
	_resolve_components()
	if weapon_mods:
		return base_recoil + weapon_mods.get_total_recoil_modifier()
	return base_recoil


func get_modified_magazine_capacity(base_capacity : int) -> int:
	_resolve_components()
	if weapon_mods:
		return maxi(base_capacity + weapon_mods.get_total_magazine_modifier(), 0)
	return base_capacity


func _resolve_components() -> void:
	if _components_resolved:
		return
	if weapon_mods == null:
		weapon_mods = _get_node_or_sibling(weapon_mods_path, "WeaponModdingComponent") as WeaponModdingComponent
	if item_condition == null:
		item_condition = _get_node_or_sibling(item_condition_path, "ItemCondition") as ItemCondition
	_components_resolved = true


func _get_node_or_sibling(path : NodePath, class_label : String) -> Node:
	if not path.is_empty() and has_node(path):
		return get_node(path)
	var parent_node := get_parent()
	if parent_node == null:
		return null
	for child in parent_node.get_children():
		if class_label == "WeaponModdingComponent" and child is WeaponModdingComponent:
			return child
		if class_label == "ItemCondition" and child is ItemCondition:
			return child
	return null

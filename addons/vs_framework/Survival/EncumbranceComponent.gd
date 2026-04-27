## EncumbranceComponent — tracks the total weight of the player's inventory.
##
## Add as a child of the player node alongside the survival attributes.
## Each frame it reads the player's inventory_data and sums item weights.
## When total weight exceeds carry_capacity the player is encumbered and
## FatigueAttribute accumulation is boosted, speed is penalised.
##
## Item weight is read from a "weight" property on InventoryItemPD resources.
## If a resource does not expose a "weight" property, item_fallback_weight is used.
##
## Wire get_speed_multiplier() into your movement code alongside FatigueAttribute.
extends Node
class_name EncumbranceComponent

signal encumbrance_changed(current_weight : float, capacity : float)
signal over_encumbered
signal encumbrance_cleared

## Maximum weight the player can carry without penalty (kilograms).
@export var carry_capacity : float = 30.0

## Speed multiplier applied when the player is at carry_capacity.
## Linearly interpolated from 1.0 at 0 kg to this value at carry_capacity.
@export_range(0.1, 1.0) var max_encumbered_speed_multiplier : float = 0.6

## Extra speed penalty fraction applied when weight exceeds carry_capacity (over-encumbered).
@export_range(0.0, 0.9) var over_encumbered_penalty : float = 0.3

## Weight assigned to items that have no "weight" property.
@export var item_fallback_weight : float = 0.5

## How often (in seconds) the inventory is re-scanned to update total weight.
@export var scan_interval : float = 0.5

## Optional reference to FatigueAttribute. If set, over-encumbrance boosts fatigue.
@export_node_path("FatigueAttribute") var fatigue_attribute_path : NodePath = NodePath("")

## Fatigue accumulation rate multiplier applied when over-encumbered.
@export var over_encumbered_fatigue_multiplier : float = 2.0

var current_weight : float = 0.0
var is_over_encumbered : bool = false

var _scan_timer : float = 0.0
var _fatigue_attr : FatigueAttribute = null
var _player_node : Node = null
var _prev_over_encumbered : bool = false


func _ready() -> void:
	call_deferred("_find_references")


func _process(delta : float) -> void:
	_scan_timer += delta
	if _scan_timer >= scan_interval:
		_scan_timer = 0.0
		_update_weight()


# ─── Public API ───────────────────────────────────────────────────────────────

## Returns a 0–1 speed multiplier to apply to the player's movement speed.
## Encumbrance reduces speed linearly; over-encumbrance adds a flat extra penalty.
func get_speed_multiplier() -> float:
	var ratio : float = clamp(current_weight / max(carry_capacity, 1.0), 0.0, 1.0)
	var base_mult : float = lerp(1.0, max_encumbered_speed_multiplier, ratio)
	if is_over_encumbered:
		base_mult = max(base_mult - over_encumbered_penalty, 0.1)
	return base_mult


## Returns how many kg of free carry capacity remain (clamped to 0).
func get_remaining_capacity() -> float:
	return max(carry_capacity - current_weight, 0.0)


# ─── Internal ─────────────────────────────────────────────────────────────────

func _update_weight() -> void:
	if not _player_node:
		return

	var inventory = _player_node.get("inventory_data")
	if not inventory:
		return

	var total : float = 0.0
	var slots : Array = []

	# Support both Array and InventoryData node variants used by COGITO.
	if inventory.get("inventory_slots") != null:
		slots = inventory.inventory_slots
	elif inventory is Array:
		slots = inventory

	for slot in slots:
		if slot == null:
			continue
		var item : Object = _get_item_from_slot(slot)
		if item == null:
			continue
		var weight : float = _get_item_weight(item)
		var quantity : int = _get_slot_quantity(slot)
		total += weight * quantity

	current_weight = total
	var over : bool = current_weight > carry_capacity
	encumbrance_changed.emit(current_weight, carry_capacity)

	if over and not _prev_over_encumbered:
		is_over_encumbered = true
		over_encumbered.emit()
		_apply_fatigue_penalty(true)
	elif not over and _prev_over_encumbered:
		is_over_encumbered = false
		encumbrance_cleared.emit()
		_apply_fatigue_penalty(false)

	_prev_over_encumbered = over


func _apply_fatigue_penalty(enable : bool) -> void:
	if not _fatigue_attr:
		return
	if enable:
		_fatigue_attr.accumulation_rate *= over_encumbered_fatigue_multiplier
	else:
		_fatigue_attr.accumulation_rate /= over_encumbered_fatigue_multiplier


func _find_references() -> void:
	_player_node = get_parent()
	if not fatigue_attribute_path.is_empty():
		_fatigue_attr = get_node_or_null(fatigue_attribute_path) as FatigueAttribute


# ─── Slot / item helpers ───────────────────────────────────────────────────────

## Extracts the InventoryItemPD from a COGITO inventory slot (Dictionary or Object).
func _get_item_from_slot(slot) -> Object:
	if slot is Dictionary:
		return slot.get("inventory_item", null)
	if "inventory_item" in slot:
		return slot.inventory_item
	return null


## Returns the weight of an inventory item resource. Falls back to item_fallback_weight.
func _get_item_weight(item : Object) -> float:
	if item is Dictionary:
		return float(item.get("weight", item_fallback_weight))
	if "weight" in item:
		return float(item.weight)
	return item_fallback_weight


## Returns the stack quantity from a COGITO inventory slot (Dictionary or Object).
func _get_slot_quantity(slot) -> int:
	if slot is Dictionary:
		return int(slot.get("quantity", 1))
	if "quantity" in slot:
		return int(slot.quantity)
	return 1

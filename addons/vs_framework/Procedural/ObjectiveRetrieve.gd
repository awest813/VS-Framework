## ObjectiveRetrieve — complete by picking up a specific item.
##
## Wire the pickup component's item_picked_up signal (or use _process check)
## to check if the target item has been collected.
extends ObjectiveBase
class_name ObjectiveRetrieve

## Name of the item to retrieve (must match InventoryItemPD.name exactly).
@export var target_item_name : String = ""

var _player_node : Node = null


func _on_activated() -> void:
	call_deferred("_find_player")


func _find_player() -> void:
	_player_node = get_tree().get_first_node_in_group("Player")


func _process(_delta : float) -> void:
	if not is_active or is_complete or not _player_node:
		return

	var inventory = _player_node.get("inventory_data")
	if not inventory:
		return

	var inventory_slots = _get_inventory_slots(inventory)
	if not inventory_slots:
		return

	for slot in inventory_slots:
		if _get_slot_item_name(slot) == target_item_name and _get_slot_quantity(slot) > 0:
			complete()
			return


func _get_slot_item_name(slot) -> String:
	if slot == null:
		return ""
	var item = _get_variant_property(slot, "inventory_item")
	if item == null:
		return ""
	var item_name = _get_variant_property(item, "name")
	return str(item_name) if item_name != null else ""


func _get_slot_quantity(slot) -> int:
	if slot == null:
		return 0
	var quantity = _get_variant_property(slot, "quantity")
	return int(quantity) if quantity != null else 0


func _get_inventory_slots(inventory):
	return _get_variant_property(inventory, "inventory_slots")


func _get_variant_property(source, property_name : String):
	if source is Dictionary:
		return source.get(property_name)
	if source is Object:
		return source.get(property_name)
	return null

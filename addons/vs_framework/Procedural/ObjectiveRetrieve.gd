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

	var inventory_slots := VSInventorySlotUtils.get_inventory_slots(inventory)
	if not inventory_slots:
		return

	for slot in inventory_slots:
		if VSInventorySlotUtils.get_slot_item_name(slot) == target_item_name \
				and VSInventorySlotUtils.get_slot_quantity(slot) > 0:
			complete()
			return

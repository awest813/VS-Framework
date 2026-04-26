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

	if not _player_node.inventory_data:
		return

	for slot in _player_node.inventory_data.inventory_slots:
		if slot != null and slot.inventory_item != null:
			if slot.inventory_item.name == target_item_name and slot.quantity > 0:
				complete()
				return

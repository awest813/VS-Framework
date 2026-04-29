extends RefCounted
class_name VSInventorySlotUtils


static func get_inventory_slots(inventory) -> Array:
	var slots = get_property_or_null(inventory, "inventory_slots")
	return slots if slots is Array else []


static func get_slot_item_name(slot) -> String:
	var item = get_property_or_null(slot, "inventory_item")
	if item == null:
		return ""
	var item_name = get_property_or_null(item, "name")
	return str(item_name) if item_name != null else ""


static func get_slot_quantity(slot) -> int:
	var quantity = get_property_or_null(slot, "quantity")
	return int(quantity) if quantity != null else 0


static func get_property_or_null(source, property_name : String):
	if source is Dictionary or source is Object:
		return source.get(property_name)
	return null

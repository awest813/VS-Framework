extends RefCounted
class_name VSInventorySlotUtils


static func get_inventory_slots(inventory) -> Array:
	var slots = get_variant_property(inventory, "inventory_slots")
	return slots if slots is Array else []


static func get_slot_item_name(slot) -> String:
	var item = get_variant_property(slot, "inventory_item")
	if item == null:
		return ""
	var item_name = get_variant_property(item, "name")
	return str(item_name) if item_name != null else ""


static func get_slot_quantity(slot) -> int:
	var quantity = get_variant_property(slot, "quantity")
	return int(quantity) if quantity != null else 0


static func get_variant_property(source, property_name : String):
	if source is Dictionary:
		return source.get(property_name)
	if source is Object:
		return source.get(property_name)
	return null

extends Node
class_name PersistentStashManager

## Emitted when the stash contents change.
signal stash_updated

## Save path for the persistent stash file.
const STASH_SAVE_PATH : String = "user://vs_stash.res"

## Currency key used inside the stash dictionary.
const CURRENCY_KEY : String = "currency"

## Raw stash data: Array of {item_name, quantity} dictionaries.
var stash_items : Array[Dictionary] = []

## Persistent currency (not stored as an inventory item slot).
var currency : int = 0


func _ready() -> void:
	load_stash()


## Loads the stash from disk. Safe to call if the file does not exist.
func load_stash() -> void:
	if ResourceLoader.exists(STASH_SAVE_PATH):
		var res : Resource = ResourceLoader.load(STASH_SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res and res is StashSaveData:
			stash_items = res.items.duplicate(true)
			currency = res.currency
	stash_updated.emit()


## Saves the stash to disk.
func save_stash() -> void:
	var res := StashSaveData.new()
	res.items = stash_items.duplicate(true)
	res.currency = currency
	ResourceSaver.save(res, STASH_SAVE_PATH)


## Adds a batch of {item_name, quantity} dicts coming in from a successful extraction.
func commit_extraction(extracted_items : Array[Dictionary], earned_currency : int) -> void:
	for entry in extracted_items:
		_add_item(entry.get("item_name", ""), entry.get("quantity", 1))
	currency += earned_currency
	save_stash()
	stash_updated.emit()


## Returns how many of a given item are in the stash.
func get_item_count(item_name : String) -> int:
	for entry in stash_items:
		if entry.get("item_name", "") == item_name:
			return entry.get("quantity", 0)
	return 0


## Removes a quantity of an item from the stash. Returns true on success.
func remove_item(item_name : String, quantity : int) -> bool:
	for i in stash_items.size():
		if stash_items[i].get("item_name", "") == item_name:
			if stash_items[i]["quantity"] >= quantity:
				stash_items[i]["quantity"] -= quantity
				if stash_items[i]["quantity"] <= 0:
					stash_items.remove_at(i)
				save_stash()
				stash_updated.emit()
				return true
			return false
	return false


## Spends currency. Returns true if there was enough.
func spend_currency(amount : int) -> bool:
	if currency >= amount:
		currency -= amount
		save_stash()
		stash_updated.emit()
		return true
	return false


func _add_item(item_name : String, quantity : int) -> void:
	if item_name.is_empty():
		return
	for entry in stash_items:
		if entry.get("item_name", "") == item_name:
			entry["quantity"] = entry.get("quantity", 0) + quantity
			return
	stash_items.append({"item_name": item_name, "quantity": quantity})

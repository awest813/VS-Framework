## FieldCacheStash — an in-raid interactable stash that persists between runs.
##
## Place in your raid level and assign a unique cache_id. The contents survive
## even if the player dies; items deposited here are NOT lost on death.
## On successful extraction the stash is NOT automatically moved to the hub stash —
## the player must retrieve items from the field cache on a future run.
##
## Wire to COGITO's interact signal or call interact() from your interaction component.
##
## Contents are saved to user://vs_field_caches.res (a single shared file for all
## field cache instances, keyed by cache_id).
extends Node3D
class_name FieldCacheStash

signal stash_opened(contents : Array[Dictionary])
signal stash_deposited(item : Dictionary)
signal stash_retrieved(item : Dictionary)

const SAVE_PATH : String = "user://vs_field_caches.res"

## Globally unique identifier for this cache location.
## Must be stable across game sessions (don't use random values).
@export var cache_id : String = ""

## Maximum number of item stacks this cache can hold.
@export var max_slots : int = 20

## Whether this cache is initially locked (requires a key item to unlock).
@export var is_locked : bool = false

## Item name of the key required to unlock this cache.
@export var key_item_name : String = ""

## Current contents: Array of {item_name : String, quantity : int}.
var contents : Array[Dictionary] = []
var is_unlocked : bool = false


func _ready() -> void:
	if cache_id.is_empty():
		push_warning("FieldCacheStash: cache_id is empty — contents will not persist.")
	_load_contents()
	is_unlocked = not is_locked


# ─── Public API ───────────────────────────────────────────────────────────────

## Called by COGITO's interaction system.
func interact(player_interaction_component : Node) -> void:
	if is_locked and not is_unlocked:
		var player : Node = player_interaction_component.get_parent()
		if _player_has_key(player):
			is_unlocked = true
			CogitoGlobals.debug_log(true, "FieldCacheStash", cache_id + " unlocked with key.")
		else:
			player_interaction_component.send_hint(null, "Locked. Requires: " + key_item_name)
			return
	stash_opened.emit(contents.duplicate())


## Deposits one item stack into the stash. Returns false if stash is full.
func deposit(item_name : String, quantity : int) -> bool:
	if item_name.is_empty() or quantity <= 0:
		return false
	if contents.size() >= max_slots and not _find_stack(item_name):
		CogitoGlobals.debug_log(true, "FieldCacheStash", cache_id + " is full.")
		return false
	_add_to_contents(item_name, quantity)
	_save_contents()
	var item := {"item_name": item_name, "quantity": quantity}
	stash_deposited.emit(item)
	CogitoGlobals.debug_log(true, "FieldCacheStash",
		cache_id + " deposit: " + item_name + " x" + str(quantity))
	return true


## Retrieves a quantity of an item from the stash. Returns the amount actually retrieved.
func retrieve(item_name : String, quantity : int) -> int:
	var stack : Dictionary = _find_stack(item_name)
	if stack.is_empty():
		return 0
	var available : int = stack.get("quantity", 0)
	var taken : int = min(quantity, available)
	stack["quantity"] = available - taken
	if stack["quantity"] <= 0:
		contents.erase(stack)
	_save_contents()
	stash_retrieved.emit({"item_name": item_name, "quantity": taken})
	CogitoGlobals.debug_log(true, "FieldCacheStash",
		cache_id + " retrieve: " + item_name + " x" + str(taken))
	return taken


## Returns a read-only copy of the current contents.
func get_contents() -> Array[Dictionary]:
	return contents.duplicate(true)


# ─── Internal ─────────────────────────────────────────────────────────────────

func _add_to_contents(item_name : String, quantity : int) -> void:
	var stack : Dictionary = _find_stack(item_name)
	if not stack.is_empty():
		stack["quantity"] = stack.get("quantity", 0) + quantity
	else:
		contents.append({"item_name": item_name, "quantity": quantity})


func _find_stack(item_name : String) -> Dictionary:
	for stack : Dictionary in contents:
		if stack.get("item_name", "") == item_name:
			return stack
	return {}


func _player_has_key(player : Node) -> bool:
	if key_item_name.is_empty() or not player:
		return false
	var inventory = player.get("inventory_data")
	if not inventory:
		return false
	# Check COGITO inventory slots for the key item name.
	var slots : Array = []
	if inventory.get("inventory_slots") != null:
		slots = inventory.inventory_slots
	for slot in slots:
		if slot == null:
			continue
		var item : Object = _get_item_from_slot(slot)
		if item == null:
			continue
		var item_name : String = item.get("name") if item is Dictionary else (item.name if "name" in item else "")
		if item_name == key_item_name:
			return true
	return false


## Extracts the inventory item resource from a COGITO slot (Dictionary or Object).
func _get_item_from_slot(slot) -> Object:
	if slot is Dictionary:
		return slot.get("inventory_item", null)
	if "inventory_item" in slot:
		return slot.inventory_item
	return null


func _save_contents() -> void:
	if cache_id.is_empty():
		return
	var all_data : Dictionary = _load_all_data()
	all_data[cache_id] = contents.duplicate(true)
	var res := FieldCacheSaveData.new()
	res.cache_data = all_data
	ResourceSaver.save(res, SAVE_PATH)


func _load_contents() -> void:
	if cache_id.is_empty():
		return
	var all_data : Dictionary = _load_all_data()
	if all_data.has(cache_id):
		contents = all_data[cache_id].duplicate(true)


func _load_all_data() -> Dictionary:
	if not ResourceLoader.exists(SAVE_PATH):
		return {}
	var res : Resource = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res and res is FieldCacheSaveData:
		return res.cache_data.duplicate(true)
	return {}

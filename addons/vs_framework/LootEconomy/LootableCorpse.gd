## LootableCorpse — spawnable node that appears when an NPC is killed.
##
## Instantiate from your NPC's death handler (connect to COGITO's death signal or
## override the NPC's die() method) and add it to the current scene at the NPC's
## world position. Players interact with it via COGITO's interaction system.
##
## Example (inside NPC die() override):
##   var corpse : LootableCorpse = corpse_scene.instantiate()
##   get_tree().current_scene.add_child(corpse)
##   corpse.global_position = global_position
##   corpse.guaranteed_items = [{"item_name": "ak74_mag", "quantity": 1}]
##   corpse.loot_table = enemy_loot_table
extends Node3D
class_name LootableCorpse

signal looted(items : Array[Dictionary])
signal corpse_despawned

## How long in seconds before the corpse despawns. Use -1 for no despawn.
@export var despawn_time : float = 120.0

## ExtractionLootTable resource used to roll randomised items. Optional.
@export var loot_table : ExtractionLootTable

## Items always placed on the corpse regardless of loot table.
## Each entry is a Dictionary with at minimum {"item_name": String, "quantity": int}.
@export var guaranteed_items : Array[Dictionary] = []

## Whether this corpse has already been looted.
var is_looted : bool = false

var _contents : Array[Dictionary] = []
var _despawn_timer : float = 0.0


func _ready() -> void:
	_generate_contents()
	if despawn_time > 0.0:
		_despawn_timer = despawn_time


func _process(delta : float) -> void:
	if despawn_time <= 0.0 or is_looted:
		return
	_despawn_timer -= delta
	if _despawn_timer <= 0.0:
		_despawn()


# ─── Public API ───────────────────────────────────────────────────────────────

## Called by COGITO's interaction system. Wire to an InteractableComponent on
## the same node (or on a child mesh / trigger area).
func interact(player_interaction_component : Node) -> void:
	if is_looted:
		player_interaction_component.send_hint(null, "Already looted.")
		return
	open_loot(player_interaction_component.get_parent())


## Opens the corpse loot to the player. Transfers all contents and emits looted.
## The actual item-pickup loop must be handled by the caller or a UI layer that
## iterates get_contents() — here we just mark the corpse and emit the signal.
func open_loot(player : Node) -> void:
	if is_looted:
		return
	is_looted = true

	# Attempt to push items directly into COGITO inventory if available.
	if player and player.get("inventory_data") != null:
		for item : Dictionary in _contents:
			var item_name : String = item.get("item_name", "")
			var qty : int = item.get("quantity", 1)
			if item_name.is_empty():
				continue
			# COGITO's inventory uses pick_up_item(resource, quantity).
			# Callers that have the actual InventoryItemPD resource should pass it;
			# here we emit the signal so the UI layer can handle it gracefully.
			CogitoGlobals.debug_log(true, "LootableCorpse",
				"Transfer item to inventory: " + item_name + " x" + str(qty))

	looted.emit(_contents.duplicate())
	CogitoGlobals.debug_log(true, "LootableCorpse",
		name + " looted — " + str(_contents.size()) + " item(s).")
	queue_free()


## Returns the current loot contents for UI display before committing the transfer.
func get_contents() -> Array[Dictionary]:
	return _contents


# ─── Internal ─────────────────────────────────────────────────────────────────

func _generate_contents() -> void:
	_contents.clear()
	for item : Dictionary in guaranteed_items:
		_contents.append(item.duplicate())
	if loot_table:
		var filtered : Array = loot_table.get_filtered_drops()
		for drop in filtered:
			if randf() < drop.get("drop_chance", 1.0):
				_contents.append({
					"item_name": drop.get("item_name", ""),
					"quantity": drop.get("quantity", 1),
				})
	CogitoGlobals.debug_log(true, "LootableCorpse",
		name + " generated " + str(_contents.size()) + " item(s).")


func _despawn() -> void:
	corpse_despawned.emit()
	CogitoGlobals.debug_log(true, "LootableCorpse", name + " despawned (timer).")
	queue_free()

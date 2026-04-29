extends Resource
class_name RunSessionResource

## Snapshot of the stash inventory taken before deploying, so we know what was brought in.
@export var stash_snapshot : Array[Dictionary] = []

## Items currently in the raid inventory (built up during the run).
@export var raid_inventory : Array[Dictionary] = []

## Elapsed raid time in seconds.
@export var elapsed_time : float = 0.0

## Name / id of the mission being run.
@export var mission_id : String = ""

## Currency carried into the raid.
@export var currency_in : int = 0

## Whether the player is currently alive in a raid.
@export var is_alive : bool = true


## Wipes all transient raid data. Called on death or when starting a fresh run.
func wipe() -> void:
	stash_snapshot.clear()
	raid_inventory.clear()
	elapsed_time = 0.0
	mission_id = ""
	currency_in = 0
	is_alive = true


## Takes a snapshot of the stash before deployment so losses can be calculated.
func snapshot_stash(inventory_slots: Array) -> void:
	stash_snapshot.clear()
	for slot in inventory_slots:
		var item_name := VSInventorySlotUtils.get_slot_item_name(slot)
		if not item_name.is_empty():
			stash_snapshot.append({
				"item_name": item_name,
				"quantity": VSInventorySlotUtils.get_slot_quantity(slot)
			})

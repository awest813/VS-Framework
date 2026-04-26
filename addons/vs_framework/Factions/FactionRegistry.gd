## FactionRegistry — autoload that tracks all faction definitions and player reputation.
##
## Reputation is stored as an integer per faction:
##   < -500  → Hostile
##   -500..500 → Neutral
##   > 500   → Friendly
##
## Reputation changes are persisted inside the PersistentStashManager save via a
## separate file so they survive across raids.
extends Node

signal reputation_changed(faction_id : String, new_reputation : int)
signal faction_stance_changed(faction_id : String, new_stance : int)

const SAVE_PATH : String = "user://vs_factions.res"

const HOSTILE_THRESHOLD : int = -500
const FRIENDLY_THRESHOLD : int = 500

## Register all FactionDefinition resources here in the editor (or at runtime).
@export var factions : Array[FactionDefinition] = []

## Runtime reputation dictionary: { faction_id : int }
var _reputation : Dictionary = {}


func _ready() -> void:
	_load_reputation()
	for faction in factions:
		if not _reputation.has(faction.faction_id):
			_reputation[faction.faction_id] = 0


# ─── Public API ───────────────────────────────────────────────────────────────

## Returns the player's current reputation with a faction (raw integer).
func get_reputation(faction_id : String) -> int:
	return _reputation.get(faction_id, 0)


## Modifies reputation with a faction by delta. Clamps to [-1000, 1000].
func change_reputation(faction_id : String, delta : int) -> void:
	var current : int = _reputation.get(faction_id, 0)
	var new_val : int = clamp(current + delta, -1000, 1000)
	_reputation[faction_id] = new_val
	reputation_changed.emit(faction_id, new_val)

	# Check if stance crossed a threshold
	faction_stance_changed.emit(faction_id, get_stance(faction_id))
	_save_reputation()


## Returns 0 (friendly), 1 (neutral), or 2 (hostile) based on current reputation.
func get_stance(faction_id : String) -> int:
	var rep : int = get_reputation(faction_id)
	if rep >= FRIENDLY_THRESHOLD:
		return 0
	elif rep <= HOSTILE_THRESHOLD:
		return 2
	return 1


## Returns whether two factions are hostile to each other (checks definition tables).
func are_factions_hostile(faction_a : String, faction_b : String) -> bool:
	for faction in factions:
		if faction.faction_id == faction_a:
			return faction_b in faction.hostile_to
	return false


## Returns the FactionDefinition for a given id, or null.
func get_faction(faction_id : String) -> FactionDefinition:
	for faction in factions:
		if faction.faction_id == faction_id:
			return faction
	return null


# ─── Persistence ──────────────────────────────────────────────────────────────

func _save_reputation() -> void:
	var res := FactionSaveData.new()
	res.reputation = _reputation.duplicate()
	ResourceSaver.save(res, SAVE_PATH)


func _load_reputation() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var res : Resource = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res and res is FactionSaveData:
			_reputation = res.reputation.duplicate()

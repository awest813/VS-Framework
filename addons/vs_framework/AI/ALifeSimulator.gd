## ALifeSimulator — resolves off-screen faction activity between raids.
##
## Call simulate_world(days_elapsed) when the player loads into the hub after a
## run. The simulator fast-resolves faction skirmishes and territory changes as
## simple probability rolls, then emits events for the hub to narrate.
extends Node
class_name ALifeSimulator

signal territory_changed(faction_id : String, territory_delta : int)
signal faction_skirmish_resolved(winner_id : String, loser_id : String)

## How many territory points each faction starts with.
@export var starting_territory : int = 10

## Maximum territory any faction can hold.
@export var max_territory : int = 50

## Per-day base probability that two hostile factions will clash.
@export var skirmish_chance_per_day : float = 0.3

var _territory : Dictionary = {}  # { faction_id : int }


func _ready() -> void:
	if FactionRegistry:
		for faction in FactionRegistry.factions:
			_territory[faction.faction_id] = starting_territory


## Simulate the given number of in-world days passing.
func simulate_world(days_elapsed : int) -> void:
	if not FactionRegistry:
		return

	var factions : Array = FactionRegistry.factions
	if factions.is_empty():
		return

	for _day in days_elapsed:
		for i in factions.size():
			for j in range(i + 1, factions.size()):
				var fa : FactionDefinition = factions[i]
				var fb : FactionDefinition = factions[j]
				if FactionRegistry.are_factions_hostile(fa.faction_id, fb.faction_id):
					if randf() < skirmish_chance_per_day:
						_resolve_skirmish(fa.faction_id, fb.faction_id)


## Returns how much territory a faction currently controls.
func get_territory(faction_id : String) -> int:
	return _territory.get(faction_id, starting_territory)


# ─── Internal ─────────────────────────────────────────────────────────────────

func _resolve_skirmish(fa_id : String, fb_id : String) -> void:
	# Simple coin-flip weighted by territory (more territory = slightly better odds)
	var ta : int = get_territory(fa_id)
	var tb : int = get_territory(fb_id)
	var total : int = ta + tb
	var winner_id : String
	var loser_id : String

	if randf() < float(ta) / float(max(total, 1)):
		winner_id = fa_id
		loser_id = fb_id
	else:
		winner_id = fb_id
		loser_id = fa_id

	var gained : int = randi_range(1, 3)
	_territory[winner_id] = min(_territory.get(winner_id, starting_territory) + gained, max_territory)
	_territory[loser_id] = max(_territory.get(loser_id, starting_territory) - gained, 0)

	territory_changed.emit(winner_id, gained)
	territory_changed.emit(loser_id, -gained)
	faction_skirmish_resolved.emit(winner_id, loser_id)

	CogitoGlobals.debug_log(true, "ALifeSimulator",
		winner_id + " beat " + loser_id + " (+/-" + str(gained) + " territory)")

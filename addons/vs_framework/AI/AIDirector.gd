## AIDirector — zone-level spawn budget system.
##
## Place one AIDirector node in a raid scene. Feed it a RoomData graph and
## call spawn_encounters() after all room geometry is placed.
##
## Supports reinforcement waves triggered by player actions.
extends Node
class_name AIDirector

signal reinforcements_incoming(room_id : String)

## The NPC scene to spawn (should be a CogitoNPC or VS-extended variant).
@export var enemy_scene : PackedScene

## Base spawn budget (max enemies per critical-path depth unit).
@export var budget_per_depth : int = 2

## Fraction of critical-path depth at which bots start force-alerted (0–1).
@export var alert_depth_fraction : float = 0.6

## How many extra enemies arrive in a reinforcement wave.
@export var reinforcement_count : int = 3

## Radius around a room centre in which bots are spread.
@export var spawn_spread_radius : float = 2.0

## Faction id assigned to all enemies spawned by this director.
@export var enemy_faction_id : String = "enemy"

var _room_graph : Array = []  # Array of RoomData
var _max_depth : int = 0
var _spawned_npcs : Array[Node] = []


## Feed the room graph from GridMapGenerator before calling spawn_encounters().
func set_room_graph(rooms : Array) -> void:
	_room_graph = rooms
	_max_depth = 0
	for room in rooms:
		if room.depth > _max_depth:
			_max_depth = room.depth


## Spawns enemies across all rooms based on budget rules.
func spawn_encounters() -> void:
	if not enemy_scene:
		push_warning("AIDirector: enemy_scene is not set.")
		return

	for room in _room_graph:
		var count : int = _budget_for_room(room)
		if count <= 0:
			continue

		var force_alerted : bool = false
		if _max_depth > 0:
			force_alerted = float(room.depth) / float(_max_depth) >= alert_depth_fraction

		for i in count:
			_spawn_in_room(room, force_alerted)


## Call this when the player fires a weapon or completes the objective to trigger reinforcements.
func trigger_reinforcements(near_room_id : String) -> void:
	var target_room : Object = _find_room(near_room_id)
	if not target_room:
		return

	reinforcements_incoming.emit(near_room_id)

	for i in reinforcement_count:
		_spawn_in_room(target_room, true)

	CogitoGlobals.debug_log(true, "AIDirector", "Reinforcements spawned near room: " + near_room_id)


# ─── Internal ─────────────────────────────────────────────────────────────────

func _budget_for_room(room : Object) -> int:
	match room.room_type:
		"objective":
			return clamp(budget_per_depth * 2, 1, 4)
		"loot", "airlock":
			if randf() < 0.5:
				return 1
			return 0
		"junction":
			return clamp(budget_per_depth, 1, 2)
		"corridor":
			if randf() < 0.4:
				return 1
			return 0
		"spawn":
			return 0
		"extraction":
			return 0
		_:
			return 0


func _spawn_in_room(room : Object, force_alerted : bool) -> void:
	var npc : Node3D = enemy_scene.instantiate() as Node3D
	if not npc:
		return

	get_tree().current_scene.add_child(npc)

	# Spread bots in a ring
	var angle : float = randf() * TAU
	var offset := Vector3(cos(angle), 0, sin(angle)) * randf_range(0, spawn_spread_radius)
	npc.global_position = room.world_position + offset

	# Force-alert if past the alert threshold
	if force_alerted and npc.has_method("force_alert"):
		npc.force_alert()

	# Assign faction if supported
	if "faction_id" in npc:
		npc.faction_id = enemy_faction_id

	_spawned_npcs.append(npc)
	CogitoGlobals.debug_log(true, "AIDirector", "Spawned NPC in room " + room.room_id + (", ALERTED" if force_alerted else ""))


func _find_room(room_id : String) -> Object:
	for room in _room_graph:
		if room.room_id == room_id:
			return room
	return null

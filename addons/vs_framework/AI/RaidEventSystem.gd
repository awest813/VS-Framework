## RaidEventSystem — fires random in-raid events to create emergent pressure.
##
## Add one RaidEventSystem node to your raid scene. Feed it the room graph from
## GridMapGenerator and optionally an AIDirector reference. Events are rolled at
## a random interval and chosen from the enabled event pool.
##
## Void Sovereigns event types:
##   PATROL_INCURSION   — A new enemy patrol is spawned in a random room.
##   FACTION_SKIRMISH   — Two hostile NPC groups fight near the player's area.
##   EXTRACTION_SEALED  — One extraction zone is temporarily locked.
##   LOOT_CACHE_MARKED  — A hidden loot cache location is broadcast as a signal.
##   ANOMALY_SURGE      — All anomalies in the current room briefly intensify.
##   REINFORCEMENT_CALL — The director triggers a reinforcement wave.
extends Node
class_name RaidEventSystem

signal event_fired(event_type : int, context : Dictionary)
signal patrol_incursion(room_id : String)
signal faction_skirmish(room_a_id : String, room_b_id : String)
signal extraction_sealed(extraction_zone_name : String)
signal loot_cache_marked(world_position : Vector3)
signal anomaly_surge(room_id : String)
signal reinforcement_call(room_id : String)

enum RaidEvent {
	PATROL_INCURSION,
	FACTION_SKIRMISH,
	EXTRACTION_SEALED,
	LOOT_CACHE_MARKED,
	ANOMALY_SURGE,
	REINFORCEMENT_CALL,
}

## Minimum seconds between events.
@export var min_event_interval : float = 90.0

## Maximum seconds between events.
@export var max_event_interval : float = 240.0

## Which event types are enabled in the current mission.
@export var enabled_events : Array[RaidEvent] = [
	RaidEvent.PATROL_INCURSION,
	RaidEvent.FACTION_SKIRMISH,
	RaidEvent.LOOT_CACHE_MARKED,
	RaidEvent.ANOMALY_SURGE,
	RaidEvent.REINFORCEMENT_CALL,
]

## Whether events fire automatically on a timer (set false to fire manually).
@export var auto_fire : bool = true

## Optional reference to the AIDirector for spawning reinforcements / patrols.
@export_node_path("AIDirector") var ai_director_path : NodePath = NodePath("")

## Names of ExtractionZone nodes in the scene (for EXTRACTION_SEALED events).
@export var extraction_zone_names : Array[String] = []

var _room_graph : Array = []
var _event_timer : float = 0.0
var _next_event_time : float = 0.0
var _ai_director : AIDirector = null


func _ready() -> void:
	if not ai_director_path.is_empty():
		_ai_director = get_node_or_null(ai_director_path) as AIDirector
	_schedule_next_event()


func _process(delta : float) -> void:
	if not auto_fire or enabled_events.is_empty():
		return
	_event_timer += delta
	if _event_timer >= _next_event_time:
		_event_timer = 0.0
		fire_random_event()
		_schedule_next_event()


# ─── Public API ───────────────────────────────────────────────────────────────

## Feeds the room graph from GridMapGenerator.
func set_room_graph(rooms : Array) -> void:
	_room_graph = rooms


## Fires a randomly selected event from the enabled pool.
func fire_random_event() -> void:
	if enabled_events.is_empty():
		return
	var chosen : RaidEvent = enabled_events[randi() % enabled_events.size()]
	fire_event(chosen)


## Fires a specific event type with optional room context.
func fire_event(event_type : RaidEvent, room_id : String = "") -> void:
	var context : Dictionary = {}
	match event_type:
		RaidEvent.PATROL_INCURSION:
			_fire_patrol_incursion(context)
		RaidEvent.FACTION_SKIRMISH:
			_fire_faction_skirmish(context)
		RaidEvent.EXTRACTION_SEALED:
			_fire_extraction_sealed(context)
		RaidEvent.LOOT_CACHE_MARKED:
			_fire_loot_cache_marked(context)
		RaidEvent.ANOMALY_SURGE:
			_fire_anomaly_surge(context, room_id)
		RaidEvent.REINFORCEMENT_CALL:
			_fire_reinforcement_call(context, room_id)
	context["event_type"] = event_type
	event_fired.emit(event_type, context)
	CogitoGlobals.debug_log(true, "RaidEventSystem",
		"Event fired: " + RaidEvent.keys()[event_type] + " — " + str(context))


# ─── Event handlers ────────────────────────────────────────────────────────────

func _fire_patrol_incursion(context : Dictionary) -> void:
	var room = _random_room_of_type(["junction", "corridor", "loot"])
	if not room:
		return
	context["room_id"] = room.room_id
	patrol_incursion.emit(room.room_id)
	if _ai_director:
		_ai_director.trigger_reinforcements(room.room_id)


func _fire_faction_skirmish(context : Dictionary) -> void:
	var room_a = _random_room()
	var room_b = _random_room()
	if not room_a or not room_b or room_a == room_b:
		return
	context["room_a"] = room_a.room_id
	context["room_b"] = room_b.room_id
	faction_skirmish.emit(room_a.room_id, room_b.room_id)


func _fire_extraction_sealed(context : Dictionary) -> void:
	if extraction_zone_names.is_empty():
		return
	var zone_name : String = extraction_zone_names[randi() % extraction_zone_names.size()]
	var zone : Node = get_tree().current_scene.find_child(zone_name, true, false)
	if zone and zone.has_method("seal_zone"):
		zone.seal_zone()
	context["zone_name"] = zone_name
	extraction_sealed.emit(zone_name)
	# Automatically reopen after a delay.
	get_tree().create_timer(randf_range(30.0, 90.0)).timeout.connect(
		func() -> void:
			if zone and zone.has_method("open_zone"):
				zone.open_zone()
	)


func _fire_loot_cache_marked(context : Dictionary) -> void:
	var room = _random_room_of_type(["loot", "airlock", "junction"])
	if not room:
		return
	var pos : Vector3 = room.world_position
	context["world_position"] = pos
	loot_cache_marked.emit(pos)


func _fire_anomaly_surge(context : Dictionary, hint_room_id : String) -> void:
	var room = _find_room(hint_room_id) if not hint_room_id.is_empty() else _random_room()
	if not room:
		return
	context["room_id"] = room.room_id
	anomaly_surge.emit(room.room_id)


func _fire_reinforcement_call(context : Dictionary, hint_room_id : String) -> void:
	if _ai_director:
		var room = _find_room(hint_room_id) if not hint_room_id.is_empty() else _random_room()
		if room:
			_ai_director.trigger_reinforcements(room.room_id)
			context["room_id"] = room.room_id
			reinforcement_call.emit(room.room_id)


# ─── Internal ─────────────────────────────────────────────────────────────────

func _schedule_next_event() -> void:
	_next_event_time = randf_range(min_event_interval, max_event_interval)


func _random_room() -> Object:
	if _room_graph.is_empty():
		return null
	return _room_graph[randi() % _room_graph.size()]


func _random_room_of_type(types : Array[String]) -> Object:
	var candidates : Array = []
	for room in _room_graph:
		if room.room_type in types:
			candidates.append(room)
	if candidates.is_empty():
		return _random_room()
	return candidates[randi() % candidates.size()]


func _find_room(room_id : String) -> Object:
	for room in _room_graph:
		if room.room_id == room_id:
			return room
	return null

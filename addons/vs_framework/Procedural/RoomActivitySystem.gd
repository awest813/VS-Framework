## RoomActivitySystem — streams AI activation and audio based on player proximity.
##
## Place one in the raid scene. Feed it the room graph from GridMapGenerator
## and call set_room_graph(). The system deactivates rooms beyond the cull radius
## and activates rooms within the active radius each frame.
extends Node
class_name RoomActivitySystem

## Rooms within this many grid steps of the player are considered active.
@export var active_radius : int = 2

## How often (in seconds) the system updates room activity.
@export var update_interval : float = 1.0

## The player node reference (auto-found if blank).
@export var player_path : NodePath = NodePath("")

var _room_graph : Array = []
var _player_node : Node = null
var _update_timer : float = 0.0

## Tracks which rooms are currently active.
var _active_rooms : Array = []


func _ready() -> void:
	if not player_path.is_empty():
		_player_node = get_node_or_null(player_path)
	if not _player_node:
		call_deferred("_find_player")


## Feed the room graph from GridMapGenerator.
func set_room_graph(rooms : Array) -> void:
	_room_graph = rooms


func _process(delta : float) -> void:
	_update_timer += delta
	if _update_timer < update_interval:
		return
	_update_timer = 0.0
	_update_activity()


func _update_activity() -> void:
	if not _player_node or _room_graph.is_empty():
		return

	var player_pos : Vector3 = _player_node.global_position
	var new_active : Array = []

	for room in _room_graph:
		var dist_sq : float = (room.world_position - player_pos).length_squared()
		var radius_world : float = active_radius * 10.0  # assume 10u tile size
		var is_in_range : bool = dist_sq <= radius_world * radius_world

		if is_in_range:
			new_active.append(room)

	# Rooms that were active but are no longer — deactivate
	for room in _active_rooms:
		if not new_active.has(room):
			_deactivate_room(room)

	# Rooms that are newly active
	for room in new_active:
		if not _active_rooms.has(room):
			_activate_room(room)

	_active_rooms = new_active


func _activate_room(room : RoomData) -> void:
	CogitoGlobals.debug_log(false, "RoomActivitySystem", "Activating room: " + room.room_id)
	# Enable AI nodes tagged with room id group
	for node in get_tree().get_nodes_in_group(room.room_id):
		if node.has_method("set_physics_process"):
			node.set_physics_process(true)
			node.set_process(true)


func _deactivate_room(room : RoomData) -> void:
	CogitoGlobals.debug_log(false, "RoomActivitySystem", "Deactivating room: " + room.room_id)
	for node in get_tree().get_nodes_in_group(room.room_id):
		if node.has_method("set_physics_process"):
			node.set_physics_process(false)
			node.set_process(false)


func _find_player() -> void:
	_player_node = get_tree().get_first_node_in_group("Player")

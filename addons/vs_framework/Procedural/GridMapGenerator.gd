## GridMapGenerator — seeded grid-based level layout generator.
##
## Usage:
##   var gen := GridMapGenerator.new()
##   var rooms := gen.generate(mission_definition)
##   # rooms is an Array[RoomData]; pass it to AIDirector.set_room_graph()
##
## Critical path: spawn → [corridors] → objective → [corridors] → extraction
## Branch dead-ends become loot rooms or airlock rooms (horror pressure).
extends RefCounted
class_name GridMapGenerator

## Tile size in world units.
@export var tile_size : float = 10.0

## Room type probabilities for non-critical-path branch endings.
const BRANCH_TYPES : Array = ["loot", "airlock", "loot", "loot"]
## Minimum layout size needed to guarantee spawn, objective, and extraction rooms.
const MIN_ROOM_COUNT : int = 3
## Prevents branch growth from looping forever when most adjacent tiles are occupied.
const MAX_BRANCH_ATTEMPTS_PER_ROOM : int = 3
const MAX_CRITICAL_PATH_ATTEMPTS : int = 32
const LOG_GENERATION_WARNINGS : bool = true


## Generates a RoomData graph from a MissionDefinitionResource.
## Returns an Array of RoomData objects.
func generate(mission : MissionDefinitionResource) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = mission.level_seed if mission.level_seed != 0 else _make_runtime_seed()

	var room_count : int = max(mission.room_count, MIN_ROOM_COUNT)
	var rooms : Array = []
	var grid : Dictionary = {}  # {Vector2i: RoomData}

	# ── Build critical path ────────────────────────────────────────────────────
	var critical_path : Array = []
	var directions := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	var cp_length : int = max(MIN_ROOM_COUNT, room_count / 2)
	var path_positions : Array[Vector2i] = _generate_critical_path_positions(cp_length, directions, rng)
	for i in range(path_positions.size()):
		var pos : Vector2i = path_positions[i]
		var room := _make_room(pos, i, true)
		grid[pos] = room
		rooms.append(room)
		critical_path.append(room)

		if i > 0:
			_connect_rooms(critical_path[i - 1], room)

	# Assign types along critical path
	critical_path[0].room_type = "spawn"

	var obj_idx : int = max(1, cp_length - 2)
	critical_path[obj_idx].room_type = "objective"

	critical_path[cp_length - 1].room_type = "extraction"

	# ── Grow branches ──────────────────────────────────────────────────────────
	var branch_budget : int = room_count - cp_length
	var attempts : int = 0
	while branch_budget > 0 and attempts < room_count * MAX_BRANCH_ATTEMPTS_PER_ROOM:
		attempts += 1
		var parent : RoomData = rooms[rng.randi_range(0, rooms.size() - 1)]
		var parent_pos := Vector2i(parent.grid_x, parent.grid_y)
		var free_dirs : Array[Vector2i] = _get_available_dirs(parent_pos, grid, directions)
		if free_dirs.is_empty():
			continue

		var dir : Vector2i = free_dirs[rng.randi_range(0, free_dirs.size() - 1)]
		var new_pos := parent_pos + dir

		var branch_room := _make_room(new_pos, parent.depth + 1, false)
		branch_room.room_type = BRANCH_TYPES[rng.randi_range(0, BRANCH_TYPES.size() - 1)]
		_connect_rooms(parent, branch_room)

		grid[new_pos] = branch_room
		rooms.append(branch_room)
		branch_budget -= 1

	_update_room_shapes(rooms)

	# ── Assign world positions ─────────────────────────────────────────────────
	for room in rooms:
		room.world_position = Vector3(room.grid_x * tile_size, 0, room.grid_y * tile_size)

	return rooms


# ─── Internal helpers ──────────────────────────────────────────────────────────

func _make_room(pos : Vector2i, depth : int, on_cp : bool) -> RoomData:
	var r := RoomData.new()
	r.room_id = "room_%d_%d" % [pos.x, pos.y]
	r.grid_x = pos.x
	r.grid_y = pos.y
	r.depth = depth
	r.is_critical_path = on_cp
	r.room_type = "corridor"
	return r


func _generate_critical_path_positions(length : int, directions : Array, rng : RandomNumberGenerator) -> Array[Vector2i]:
	for _attempt in range(MAX_CRITICAL_PATH_ATTEMPTS):
		var positions : Array[Vector2i] = [Vector2i.ZERO]
		var occupied : Dictionary = {Vector2i.ZERO: true}

		while positions.size() < length:
			var current : Vector2i = positions[positions.size() - 1]
			var candidates : Array[Vector2i] = _get_available_dirs(current, occupied, directions)
			if candidates.is_empty():
				break

			var next_dir : Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
			var next_pos : Vector2i = current + next_dir
			positions.append(next_pos)
			occupied[next_pos] = true

		if positions.size() == length:
			return positions

	var fallback : Array[Vector2i] = []
	for i in range(length):
		fallback.append(Vector2i(i, 0))
	CogitoGlobals.debug_log(LOG_GENERATION_WARNINGS, "GridMapGenerator",
		"Critical path generation exhausted {0} retries while searching for a non-overlapping path of length {1}; using fallback layout. This usually means the requested path got trapped during random growth."
		.format([MAX_CRITICAL_PATH_ATTEMPTS, length]))
	return fallback


func _make_runtime_seed() -> int:
	return hash([Time.get_ticks_usec(), Time.get_unix_time_from_system(), get_instance_id()])


func _connect_rooms(a : RoomData, b : RoomData) -> void:
	if not a.neighbors.has(b):
		a.neighbors.append(b)
	if not b.neighbors.has(a):
		b.neighbors.append(a)

	var dx := b.grid_x - a.grid_x
	var dy := b.grid_y - a.grid_y

	if dx == 1:
		a.exits.append("E")
		b.exits.append("W")
	elif dx == -1:
		a.exits.append("W")
		b.exits.append("E")
	elif dy == 1:
		a.exits.append("S")
		b.exits.append("N")
	elif dy == -1:
		a.exits.append("N")
		b.exits.append("S")


func _get_available_dirs(pos : Vector2i, grid : Dictionary, dirs : Array) -> Array[Vector2i]:
	var available : Array[Vector2i] = []
	for dir in dirs:
		if not grid.has(pos + dir):
			available.append(dir)
	return available


func _update_room_shapes(rooms : Array) -> void:
	for room in rooms:
		room.exits = _unique_exits(room.exits)

		if room.room_type == "corridor" and room.exits.size() >= 3:
			room.room_type = "junction"

		room.shape = _shape_for_exits(room.exits)


## Maps exit counts to geometry hints:
## 0/1 exits stay as rooms, 2 aligned exits become straight corridors,
## 2 perpendicular exits become turns, and 3+ exits become junctions.
func _shape_for_exits(exits : Array[String]) -> String:
	if exits.size() >= 3:
		return "junction"
	if exits.size() != 2:
		return "room"

	var has_north : bool = exits.has("N")
	var has_south : bool = exits.has("S")
	var has_east : bool = exits.has("E")
	var has_west : bool = exits.has("W")

	if (has_north and has_south) or (has_east and has_west):
		return "corridor_straight"
	return "corridor_turn"


## Removes duplicate exit directions while preserving their original order.
func _unique_exits(exits : Array[String]) -> Array[String]:
	var seen : Dictionary = {}
	var unique : Array[String] = []
	for exit_dir in exits:
		if seen.has(exit_dir):
			continue
		seen[exit_dir] = true
		unique.append(exit_dir)
	return unique

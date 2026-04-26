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


## Generates a RoomData graph from a MissionDefinitionResource.
## Returns an Array of RoomData objects.
func generate(mission : MissionDefinitionResource) -> Array:
	var seed_val : int = mission.level_seed if mission.level_seed != 0 else randi()
	seed(seed_val)

	var room_count : int = mission.room_count
	var rooms : Array = []
	var grid : Dictionary = {}  # {Vector2i: RoomData}

	# ── Build critical path ────────────────────────────────────────────────────
	var critical_path : Array = []
	var pos := Vector2i(0, 0)
	var directions := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	var used_dirs : Array = []

	var cp_length : int = max(3, room_count / 2)
	for i in cp_length:
		var room := _make_room(pos, i, true)
		grid[pos] = room
		rooms.append(room)
		critical_path.append(room)

		if i > 0:
			_connect_rooms(critical_path[i - 1], room, pos - _last_dir(critical_path, i))

		if i < cp_length - 1:
			var next_dir := _pick_dir(pos, grid, directions)
			pos += next_dir
			used_dirs.append(next_dir)

	# Assign types along critical path
	critical_path[0].room_type = "spawn"
	critical_path[0].shape = "room"

	var obj_idx : int = max(1, cp_length - 2)
	critical_path[obj_idx].room_type = "objective"
	critical_path[obj_idx].shape = "room"

	critical_path[cp_length - 1].room_type = "extraction"
	critical_path[cp_length - 1].shape = "room"

	# Fill in corridor shapes for intermediate rooms
	for i in range(1, cp_length - 1):
		if critical_path[i].room_type == "corridor":
			critical_path[i].shape = "corridor_straight"

	# ── Grow branches ──────────────────────────────────────────────────────────
	var branch_budget : int = room_count - cp_length
	var attempts : int = 0
	while branch_budget > 0 and attempts < room_count * 3:
		attempts += 1
		var parent : RoomData = rooms[randi() % rooms.size()]
		var parent_pos := Vector2i(parent.grid_x, parent.grid_y)
		var dir := directions[randi() % directions.size()]
		var new_pos := parent_pos + dir

		if grid.has(new_pos):
			continue

		var branch_room := _make_room(new_pos, parent.depth + 1, false)
		branch_room.room_type = BRANCH_TYPES[randi() % BRANCH_TYPES.size()]
		branch_room.shape = "room"
		_connect_rooms(parent, branch_room, parent_pos)

		grid[new_pos] = branch_room
		rooms.append(branch_room)
		branch_budget -= 1

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


func _connect_rooms(a : RoomData, b : RoomData, _a_grid_pos : Vector2i) -> void:
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


func _pick_dir(pos : Vector2i, grid : Dictionary, dirs : Array) -> Vector2i:
	var shuffled := dirs.duplicate()
	shuffled.shuffle()
	for d in shuffled:
		if not grid.has(pos + d):
			return d
	return dirs[0]  # fallback


func _last_dir(path : Array, i : int) -> Vector2i:
	if i == 0:
		return Vector2i.ZERO
	var prev : RoomData = path[i - 1]
	var curr : RoomData = path[i]
	return Vector2i(curr.grid_x - prev.grid_x, curr.grid_y - prev.grid_y)

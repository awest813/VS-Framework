## MinimapSystem — renders a top-down 2D representation of discovered rooms.
##
## Attach to a SubViewportContainer or a Control node sized appropriately.
## Call set_room_graph() after GridMapGenerator runs.
## Call reveal_room(room_id) as the player enters each room.
extends Control
class_name MinimapSystem

## Visual size of each room cell in the minimap.
@export var cell_size : Vector2 = Vector2(12, 12)
@export var cell_margin : float = 2.0

## Colors per room type.
@export var color_unknown : Color = Color(0.15, 0.15, 0.15)
@export var color_corridor : Color = Color(0.3, 0.3, 0.3)
@export var color_room : Color = Color(0.4, 0.4, 0.5)
@export var color_objective : Color = Color(0.9, 0.7, 0.1)
@export var color_extraction : Color = Color(0.1, 0.9, 0.3)
@export var color_spawn : Color = Color(0.3, 0.6, 0.9)
@export var color_loot : Color = Color(0.6, 0.4, 0.2)
@export var color_player : Color = Color(1.0, 1.0, 1.0)

var _room_graph : Array = []
var _revealed : Dictionary = {}  # { room_id : bool }
var _player_room_id : String = ""


## Feed the room graph from GridMapGenerator.
func set_room_graph(rooms : Array) -> void:
	_room_graph = rooms
	queue_redraw()


## Mark a room as discovered (call when player enters a room).
func reveal_room(room_id : String) -> void:
	_revealed[room_id] = true
	_player_room_id = room_id
	queue_redraw()


func _draw() -> void:
	if _room_graph.is_empty():
		return

	# Find grid bounds by initialising from the first room to avoid float-infinity in int vars.
	if _room_graph.is_empty():
		return
	var min_x : int = (_room_graph[0] as RoomData).grid_x
	var min_y : int = (_room_graph[0] as RoomData).grid_y
	for room in _room_graph:
		min_x = min(min_x, room.grid_x)
		min_y = min(min_y, room.grid_y)

	var origin : Vector2 = Vector2(size.x / 2.0, size.y / 2.0)

	for room in _room_graph:
		var revealed : bool = _revealed.get(room.room_id, false)
		var cell_color : Color = color_unknown if not revealed else _color_for_type(room.room_type)

		var cx : float = origin.x + (room.grid_x - min_x) * (cell_size.x + cell_margin)
		var cy : float = origin.y + (room.grid_y - min_y) * (cell_size.y + cell_margin)
		var rect := Rect2(cx - cell_size.x / 2.0, cy - cell_size.y / 2.0, cell_size.x, cell_size.y)

		draw_rect(rect, cell_color)

		# Player marker
		if room.room_id == _player_room_id:
			var center := Vector2(cx, cy)
			draw_circle(center, 3.0, color_player)


func _color_for_type(room_type : String) -> Color:
	match room_type:
		"spawn":      return color_spawn
		"extraction": return color_extraction
		"objective":  return color_objective
		"loot":       return color_loot
		"airlock":    return color_loot
		_:            return color_room

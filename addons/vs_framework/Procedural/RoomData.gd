## RoomData — lightweight data object describing one room in a generated grid.
extends RefCounted
class_name RoomData

## Unique room identifier within the grid (e.g. "room_0_0").
var room_id : String = ""

## Grid coordinate.
var grid_x : int = 0
var grid_y : int = 0

## World-space centre position (set after geometry is placed).
var world_position : Vector3 = Vector3.ZERO

## Room function type: "spawn", "extraction", "objective", "loot", "corridor", "junction", "airlock"
var room_type : String = "corridor"

## Whether this room is on the main critical path.
var is_critical_path : bool = false

## Depth from the spawn room along the critical path.
var depth : int = 0

## Adjacent rooms (Array of RoomData).
var neighbors : Array = []

## Cardinal exits: ["N", "S", "E", "W"] subset.
var exits : Array[String] = []

## Tile shape hint for geometry builder: "room", "corridor_straight", "corridor_turn", "junction"
var shape : String = "room"

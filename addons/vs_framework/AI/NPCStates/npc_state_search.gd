## npc_state_search.gd
## VS Framework extended NPC state.
##
## The NPC moves to the last known suspicious position and sweeps the area.
## If the player is found they transition to hunt; if the search expires they return to patrol.
extends Node

var Host
var States

## How long to sweep the area before giving up.
@export var search_duration : float = 15.0

## Radius around the last known position to roam while searching.
@export var search_radius : float = 5.0

## Number of random search waypoints to visit before giving up.
@export var search_waypoints : int = 3

var _last_known_pos : Vector3 = Vector3.ZERO
var _waypoints_visited : int = 0
var _search_timer : Timer
var _is_moving : bool = false


func _enter_tree() -> void:
	_search_timer = Timer.new()
	_search_timer.wait_time = search_duration
	_search_timer.one_shot = true
	_search_timer.timeout.connect(_on_search_timeout)
	add_child(_search_timer)


func _state_enter(args = null) -> void:
	CogitoGlobals.debug_log(true, "npc_state_search", Host.name + " is SEARCHING")
	if args is Vector3:
		_last_known_pos = args
	elif Host.attention_target:
		_last_known_pos = Host.attention_target.global_position
	else:
		_last_known_pos = Host.global_position

	_waypoints_visited = 0
	Host.move_speed = Host.walk_speed
	_search_timer.start()
	_go_to_next_waypoint()


func _state_exit() -> void:
	States.save_state_as_previous(self.name, null)
	_search_timer.stop()


func _physics_process(delta : float) -> void:
	# If the player becomes visible, switch to hunt
	if Host.attention_target:
		States.goto("hunt")
		return

	Host.update_animations(delta)

	if not _is_moving:
		return

	if Host.navigation_agent_3d.is_navigation_finished():
		_is_moving = false
		_waypoints_visited += 1
		if _waypoints_visited >= search_waypoints:
			_on_search_timeout()
		else:
			_go_to_next_waypoint()
		return

	var next_pos : Vector3 = Host.navigation_agent_3d.get_next_path_position()
	var direction : Vector3 = Host.global_position.direction_to(next_pos)
	if direction:
		Host.velocity.x = direction.x * Host.move_speed
		Host.velocity.z = direction.z * Host.move_speed
	if not Host.is_on_floor():
		Host.velocity += Host.get_gravity() * delta
	Host.move_and_slide()


func _go_to_next_waypoint() -> void:
	var offset := Vector3(randf_range(-search_radius, search_radius), 0, randf_range(-search_radius, search_radius))
	Host.navigation_agent_3d.target_position = _last_known_pos + offset
	_is_moving = true


func _on_search_timeout() -> void:
	CogitoGlobals.debug_log(true, "npc_state_search", Host.name + " gave up searching")
	States.load_previous_state("patrol_on_path")

## npc_state_flank.gd
## VS Framework extended NPC state.
##
## Attempts to navigate around the target to attack from the side or rear.
## Activated by the AIDirector or a group coordination call.
extends Node

var Host
var States

## How far to the side of the target to aim for.
@export var flank_offset_distance : float = 4.0

## Switch to hunt if we get within this distance of the target.
@export var engage_distance : float = 2.0

var _target : Node3D = null
var _flank_point : Vector3 = Vector3.ZERO


func _state_enter(_args = null) -> void:
	_target = Host.attention_target
	if not _target:
		States.load_previous_state("hunt")
		return

	CogitoGlobals.debug_log(true, "npc_state_flank", Host.name + " is FLANKING")
	Host.move_speed = Host.sprint_speed
	_calculate_flank_point()


func _state_exit() -> void:
	_target = null
	Host.move_speed = Host.walk_speed
	States.save_state_as_previous(self.name, null)


func _physics_process(delta : float) -> void:
	if not _target or not is_instance_valid(_target):
		States.load_previous_state("hunt")
		return

	Host.update_animations(delta)

	# Recalculate every frame so we account for target movement
	_calculate_flank_point()

	var dist_to_target : float = Host.global_position.distance_to(_target.global_position)
	if dist_to_target <= engage_distance:
		States.goto("attack")
		return

	Host.navigation_agent_3d.target_position = _flank_point
	var next_pos : Vector3 = Host.navigation_agent_3d.get_next_path_position()
	var direction : Vector3 = Host.global_position.direction_to(next_pos)

	if direction:
		Host.velocity.x = direction.x * Host.move_speed
		Host.velocity.z = direction.z * Host.move_speed
	if not Host.is_on_floor():
		Host.velocity += Host.get_gravity() * delta
	Host.move_and_slide()


func _calculate_flank_point() -> void:
	if not _target:
		return
	# Perpendicular offset from the host → target direction
	var to_target : Vector3 = (_target.global_position - Host.global_position).normalized()
	var perpendicular : Vector3 = to_target.cross(Vector3.UP).normalized()
	var side : float = 1.0 if Host.global_position.x < _target.global_position.x else -1.0
	_flank_point = _target.global_position + perpendicular * side * flank_offset_distance

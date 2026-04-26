## npc_state_hunt.gd
## VS Framework extended NPC state.
##
## The NPC actively pursues and attacks the confirmed target (the player).
## Very similar to COGITO's chase state but with force_alert awareness.
extends Node

var Host
var States

@export var attack_range : float = 1.5
@export var give_up_time : float = 8.0
@export var hunt_stance : String = ""
@export var neutral_stance : String = ""

var _target : Node3D = null
var _give_up_timer : Timer


func _enter_tree() -> void:
	_give_up_timer = Timer.new()
	_give_up_timer.wait_time = give_up_time
	_give_up_timer.one_shot = true
	_give_up_timer.timeout.connect(_on_give_up)
	add_child(_give_up_timer)


func _state_enter(_args = null) -> void:
	_target = Host.attention_target
	if not _target:
		States.load_previous_state("search")
		return

	CogitoGlobals.debug_log(true, "npc_state_hunt", Host.name + " is HUNTING " + _target.name)
	Host.move_speed = Host.sprint_speed

	if hunt_stance:
		var anim_sm = Host.animation_tree.get("parameters/UpperBodyState/playback")
		if anim_sm:
			anim_sm.travel(hunt_stance)

	_give_up_timer.start()


func _state_exit() -> void:
	_target = null
	Host.move_speed = Host.walk_speed
	_give_up_timer.stop()
	States.save_state_as_previous(self.name, null)


func _physics_process(delta : float) -> void:
	if not _target or not is_instance_valid(_target):
		_on_give_up()
		return

	Host.update_animations(delta)

	var dist : float = Host.global_position.distance_to(_target.global_position)
	if dist <= attack_range:
		States.goto("attack")
		return

	Host.navigation_agent_3d.target_position = _target.global_position
	var next_pos : Vector3 = Host.navigation_agent_3d.get_next_path_position()
	var direction : Vector3 = Host.global_position.direction_to(next_pos)

	if direction:
		Host.velocity.x = direction.x * Host.move_speed
		Host.velocity.z = direction.z * Host.move_speed
	if not Host.is_on_floor():
		Host.velocity += Host.get_gravity() * delta
	Host.move_and_slide()

	# Target lost line-of-sight — reset give-up timer extension
	if Host.navigation_agent_3d.is_target_reachable():
		_give_up_timer.start()


func _on_give_up() -> void:
	CogitoGlobals.debug_log(true, "npc_state_hunt", Host.name + " lost the target")
	if neutral_stance:
		var anim_sm = Host.animation_tree.get("parameters/UpperBodyState/playback")
		if anim_sm:
			anim_sm.travel(neutral_stance)
	var last_known : Vector3 = _target.global_position if _target and is_instance_valid(_target) else Host.global_position
	States.goto("search", last_known)

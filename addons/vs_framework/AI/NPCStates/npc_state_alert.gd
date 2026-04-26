## npc_state_alert.gd
## VS Framework extended NPC state.
##
## Entered when the NPC hears a sound or catches a brief glimpse of the player.
## Plays a "what was that?" reaction, then transitions to search.
extends Node

var Host
var States

## Duration the NPC stays in the alert reaction before searching.
@export var alert_duration : float = 2.5

## Last known suspicious position to search toward.
var suspicious_position : Vector3 = Vector3.ZERO

var _timer : Timer


func _enter_tree() -> void:
	_timer = Timer.new()
	_timer.wait_time = alert_duration
	_timer.one_shot = true
	_timer.timeout.connect(_on_alert_timeout)
	add_child(_timer)


func _state_enter(args = null) -> void:
	CogitoGlobals.debug_log(true, "npc_state_alert", Host.name + " is ALERT")
	if args is Vector3:
		suspicious_position = args
	elif Host.attention_target:
		suspicious_position = Host.attention_target.global_position
	Host.move_speed = 0.0
	_timer.start()


func _state_exit() -> void:
	States.save_state_as_previous(self.name, null)


func _physics_process(_delta : float) -> void:
	# Face the suspicious position while reacting
	if suspicious_position != Vector3.ZERO:
		Host.face_direction(suspicious_position)


func _on_alert_timeout() -> void:
	# If we can see the player now, hunt them
	if Host.attention_target:
		States.goto("hunt")
	else:
		States.goto("search", suspicious_position)

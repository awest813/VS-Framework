## BleedState — status effect that drains health until a bandage consumable is used.
##
## Add as a child of the player node. Wire to HitboxComponent's damage_received
## signal by calling apply_bleed() from your damage processing code.
extends Node
class_name BleedState

signal bleed_started
signal bleed_stopped

## HP drained per second while bleeding.
@export var bleed_rate : float = 2.0

## Attribute name to drain.
@export var health_attribute_name : String = "health"

## Maximum number of simultaneous bleed stacks.
@export var max_stacks : int = 3

var _stacks : int = 0
var _is_bleeding : bool = false
var _player_node : Node = null


func _ready() -> void:
	call_deferred("_find_player")


func _process(delta : float) -> void:
	if not _is_bleeding or not _player_node:
		return
	if not _player_node.has_method("decrease_attribute"):
		return
	_player_node.decrease_attribute(health_attribute_name, bleed_rate * _stacks * delta)


## Applies one bleed stack. Call from damage code when a bleed-type hit is received.
func apply_bleed() -> void:
	_stacks = min(_stacks + 1, max_stacks)
	if not _is_bleeding:
		_is_bleeding = true
		bleed_started.emit()


## Removes all bleed stacks (call when a bandage consumable is used).
func stop_bleed() -> void:
	_stacks = 0
	_is_bleeding = false
	bleed_stopped.emit()
	CogitoGlobals.debug_log(true, "BleedState", "Bleed stopped.")


## Returns true if the player is currently bleeding.
func is_bleeding() -> bool:
	return _is_bleeding


func _find_player() -> void:
	_player_node = get_parent()

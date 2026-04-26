## ThirstAttribute — decays over time during raids. Drains health when depleted.
extends CogitoAttribute
class_name ThirstAttribute

## Thirst decay per second during a raid.
@export var decay_rate : float = 0.8

## Health drained per second when thirst reaches zero.
@export var dehydrated_health_drain : float = 1.5

@export var health_attribute_name : String = "health"

@export var is_decaying : bool = true

var _player_node : Node = null


func _ready() -> void:
	super._ready()
	call_deferred("_find_player")


func _process(delta : float) -> void:
	if not is_decaying or not _player_node:
		return

	if value_current > 0:
		subtract(decay_rate * delta)
	else:
		_player_node.decrease_attribute(health_attribute_name, dehydrated_health_drain * delta)


func _find_player() -> void:
	_player_node = get_parent()

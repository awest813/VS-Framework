## HungerAttribute — decays over time during raids. Drains stamina when depleted.
extends CogitoAttribute
class_name HungerAttribute

## Hunger decay per second during a raid.
@export var decay_rate : float = 0.5

## Stamina drained per second when hunger reaches zero.
@export var starving_stamina_drain : float = 2.0

@export var stamina_attribute_name : String = "stamina"

## Whether decay is currently active (set false in hub).
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
	elif _player_node.has_method("decrease_attribute"):
		# Starving — drain stamina
		_player_node.decrease_attribute(stamina_attribute_name, starving_stamina_drain * delta)


func _find_player() -> void:
	_player_node = get_parent()

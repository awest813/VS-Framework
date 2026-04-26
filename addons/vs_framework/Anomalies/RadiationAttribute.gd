## RadiationAttribute — COGITO attribute extension for radiation exposure.
##
## Add this as a child node of the player (alongside Health, Stamina, etc.).
## Radiation builds up from AnomalyComponents and EmissionEvents.
## Above the drain_threshold it starts draining health each second.
extends CogitoAttribute
class_name RadiationAttribute

## Radiation level above which health starts draining.
@export var drain_threshold : float = 50.0

## Health drained per second per radiation point above the threshold.
@export var health_drain_rate : float = 0.5

## Natural decay rate of radiation per second (0 = no natural decay).
@export var natural_decay_rate : float = 0.5

## Name of the health attribute to drain.
@export var health_attribute_name : String = "health"

## Whether radiation is currently decaying naturally.
@export var natural_decay_enabled : bool = true

var _player_node : Node = null


func _ready() -> void:
	super._ready()
	call_deferred("_find_player")


func _find_player() -> void:
	_player_node = get_parent()


func _process(delta : float) -> void:
	if not _player_node:
		return

	# Natural decay
	if natural_decay_enabled and value_current > 0:
		subtract(natural_decay_rate * delta)

	# Health drain above threshold
	if value_current > drain_threshold:
		var excess : float = value_current - drain_threshold
		_player_node.decrease_attribute(health_attribute_name, excess * health_drain_rate * delta)


## Adds radiation (call from AnomalyComponent or EmissionEvent).
func expose(amount : float) -> void:
	add(amount)


## Reduces radiation (call from anti-rad consumable effects).
func cleanse(amount : float) -> void:
	subtract(amount)

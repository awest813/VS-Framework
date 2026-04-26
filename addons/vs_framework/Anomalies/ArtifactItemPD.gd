## ArtifactItemPD — inventory item that provides passive attribute modifiers.
##
## While this item is anywhere in the player's inventory the modifiers are applied
## each process tick. Conflicting artifacts can be defined by their ids.
extends InventoryItemPD
class_name ArtifactItemPD

@export_group("Artifact Settings")

## Unique identifier for conflict/combination checks.
@export var artifact_id : String = ""

## Attribute modifiers applied passively. Each entry is {attribute_name, delta_per_second}.
## Positive delta = buff, negative delta = debuff.
@export var passive_modifiers : Array[ArtifactModifier] = []

## Artifact ids that this artifact conflicts with (only one can be active at a time).
@export var conflicts_with : Array[String] = []

var _player_node : Node = null
var _is_active : bool = false


## Called every frame from the player's inventory tick (wire up in your player script).
func tick(delta : float, player : Node) -> void:
	if not _is_active:
		return
	_player_node = player
	for mod in passive_modifiers:
		if mod.delta_per_second > 0:
			player.increase_attribute(mod.attribute_name, mod.delta_per_second * delta,
				ConsumableItemPD.ValueType.CURRENT)
		elif mod.delta_per_second < 0:
			player.decrease_attribute(mod.attribute_name, abs(mod.delta_per_second) * delta)


## Activates the artifact effects. Called when the item enters the player inventory.
func activate(player : Node) -> void:
	_player_node = player
	_is_active = true
	CogitoGlobals.debug_log(true, "ArtifactItemPD", name + " activated on " + player.name)


## Deactivates the artifact effects. Called when the item leaves the player inventory.
func deactivate() -> void:
	_is_active = false
	CogitoGlobals.debug_log(true, "ArtifactItemPD", name + " deactivated")


func use(_target) -> bool:
	# Artifacts are passive — they can't be directly "used"
	if _target:
		_target.player_interaction_component.send_hint(null, name + " is a passive artifact.")
	return false

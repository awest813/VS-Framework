## FoodItemPD — consumable that restores hunger (and optionally thirst).
extends ConsumableItemPD
class_name FoodItemPD

@export_group("Food Settings")

## How much hunger this restores.
@export var hunger_restore : float = 25.0

## How much thirst this restores (0 = food only, positive for liquid food).
@export var thirst_restore : float = 0.0

## Whether consuming this applies a stimulant effect to FatigueAttribute.
@export var is_stimulant : bool = false

## Stimulant suppression duration in seconds.
@export var stimulant_duration : float = 30.0


func use(target) -> bool:
	if target == null or target.is_in_group("external_inventory"):
		target = CogitoSceneManager._current_player_node

	# Restore hunger
	if hunger_restore > 0:
		var hunger : Node = target.find_child("HungerAttribute", true, false)
		if hunger:
			hunger.add(hunger_restore)

	# Restore thirst
	if thirst_restore > 0:
		var thirst : Node = target.find_child("ThirstAttribute", true, false)
		if thirst:
			thirst.add(thirst_restore)

	# Apply stimulant
	if is_stimulant:
		var fatigue : Node = target.find_child("FatigueAttribute", true, false)
		if fatigue and fatigue.has_method("apply_stimulant"):
			fatigue.apply_stimulant(stimulant_duration)

	Audio.play_sound(sound_use)

	if hint_text_on_use != "":
		target.player_interaction_component.send_hint(hint_icon_on_use, hint_text_on_use)

	return true

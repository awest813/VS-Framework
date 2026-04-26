## RaidHUDExtension — overlay node added on top of COGITO's HUD during raids.
##
## Shows radiation, hunger, thirst, fatigue bars and a bleed indicator.
## Attach to a CanvasLayer in the raid scene. Wire player attributes via export.
extends Control
class_name RaidHUDExtension

@export var radiation_bar : ProgressBar
@export var hunger_bar : ProgressBar
@export var thirst_bar : ProgressBar
@export var fatigue_bar : ProgressBar
@export var bleed_indicator : Control  # Shown/hidden
@export var compass_label : Label      # Shows cardinal direction

var _player_node : Node = null
var _radiation : RadiationAttribute = null
var _hunger : HungerAttribute = null
var _thirst : ThirstAttribute = null
var _fatigue : FatigueAttribute = null
var _bleed : BleedState = null


func _ready() -> void:
	call_deferred("_find_player")


func _process(_delta : float) -> void:
	if not _player_node:
		return

	_update_bar(radiation_bar, _radiation)
	_update_bar(hunger_bar, _hunger)
	_update_bar(thirst_bar, _thirst)
	_update_bar(fatigue_bar, _fatigue)

	if bleed_indicator:
		bleed_indicator.visible = _bleed != null and _bleed.is_bleeding()

	if compass_label and _player_node.has_method("get") and "rotation" in _player_node:
		compass_label.text = _get_cardinal(_player_node.rotation.y)


func _update_bar(bar : ProgressBar, attribute : CogitoAttribute) -> void:
	if not bar or not attribute:
		return
	bar.max_value = attribute.value_max
	bar.value = attribute.value_current


func _get_cardinal(radians : float) -> String:
	var degrees : float = fmod(rad_to_deg(-radians) + 360.0, 360.0)
	if degrees < 45 or degrees >= 315:
		return "N"
	elif degrees < 135:
		return "E"
	elif degrees < 225:
		return "S"
	return "W"


func _find_player() -> void:
	_player_node = get_tree().get_first_node_in_group("Player")
	if not _player_node:
		return
	_radiation = _player_node.find_child("RadiationAttribute", true, false)
	_hunger = _player_node.find_child("HungerAttribute", true, false)
	_thirst = _player_node.find_child("ThirstAttribute", true, false)
	_fatigue = _player_node.find_child("FatigueAttribute", true, false)
	_bleed = _player_node.find_child("BleedState", true, false)

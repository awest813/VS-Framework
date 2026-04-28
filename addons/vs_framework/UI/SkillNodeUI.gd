## SkillNodeUI — button representing one skill in the skill tree.
##
## Adapted from EveningComet/Godot-Skill-Tree SkillNode.gd (MIT).
##
## Attach this script to a Button node. Set associated_skill in the editor.
## Nest SkillNodeUI nodes inside one another in the scene tree to define
## prerequisite relationships (parent = prerequisite for its children).
##
## Expected node structure:
##   Button (SkillNodeUI.gd)
##   ├── TextureRect  ← assign to skill_icon
##   ├── Label        ← assign to rank_label
##   └── Line2D       ← assign to connector_line (optional; draws link to parent)
##
## In SkillTreeUI.ready() the tree is scanned and each SkillNodeUI has its
## skill_instance wired via set_skill_instance(). You do not need to call
## setup() manually when using SkillTreeUI.
extends Button
class_name SkillNodeUI

## Emitted when this node's button is pressed with a valid instance attached.
## SkillMenuUI listens to this signal to select the skill for upgrade.
signal upgrade_requested(node : SkillNodeUI)

## The SkillDefinition this button represents. Set in the editor.
@export var associated_skill : SkillDefinition

@export_group("Visuals")
## Optional icon display for the skill.
@export var skill_icon : TextureRect
## Shows current / max rank (e.g. "1 / 3").
@export var rank_label : Label
## Optional connector drawn toward the parent SkillNodeUI node.
@export var connector_line : Line2D

## Active (upgradable) and locked colours applied to skill_icon.
@export var active_color   : Color = Color.WHITE
@export var inactive_color : Color = Color(0.4, 0.4, 0.4, 1.0)

## The runtime instance supplied by SkillTreeUI.
var skill_instance : SkillInstance = null


func _ready() -> void:
	button_down.connect(_on_button_down)
	if get_tree():
		get_tree().root.size_changed.connect(_on_resolution_changed)
	_refresh_visuals()
	_draw_connector()


## Called by SkillTreeUI to wire the runtime instance for this node.
func set_skill_instance(instance : SkillInstance) -> void:
	skill_instance = instance
	instance.rank_changed.connect(_on_rank_changed)
	_refresh_visuals()
	_update_upgradability()


## Refreshes the rank label and icon to match the current instance state.
func _refresh_visuals() -> void:
	if associated_skill and skill_icon and associated_skill.tiers.size() > 0:
		skill_icon.texture = associated_skill.tiers[0].get("display_icon", null) \
			if associated_skill else null

	var cur : int = skill_instance.curr_rank if skill_instance else 0
	var max_r : int = associated_skill.max_rank if associated_skill else 1
	if rank_label:
		rank_label.text = "%d / %d" % [cur, max_r]


## Enables or disables this button based on PlayerProgression state.
func _update_upgradability() -> void:
	if not associated_skill:
		disabled = true
		return
	var can_upgrade : bool = PlayerProgression.can_upgrade_skill(associated_skill.skill_id)
	disabled = not can_upgrade
	if skill_icon:
		skill_icon.self_modulate = active_color if can_upgrade else inactive_color


## Draws a Line2D from this node toward its parent SkillNodeUI (if one exists).
func _draw_connector() -> void:
	if not connector_line:
		return
	if not get_parent() is SkillNodeUI:
		return
	connector_line.clear_points()
	connector_line.add_point(Vector2.ZERO)
	connector_line.add_point(
		get_parent().global_position - global_position + get_parent().size / 2.0
	)


func _on_button_down() -> void:
	if skill_instance:
		upgrade_requested.emit(self)


func _on_rank_changed(_instance : SkillInstance) -> void:
	_refresh_visuals()
	_update_upgradability()


func _on_resolution_changed() -> void:
	_draw_connector()

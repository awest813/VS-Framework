## SkillMenuUI — full-screen skill management panel.
##
## Adapted from EveningComet/Godot-Skill-Tree SkillMenu.gd (MIT).
##
## Attach this script to a Control node (e.g. a PanelContainer or TabContainer tab).
## Wire the exports in the editor, then assign skill_tree_scene to a PackedScene
## whose root is a Control with SkillTreeUI.gd attached.
##
## Suggested node layout:
##   Control (SkillMenuUI.gd)
##   ├── HBoxContainer
##   │   ├── ScrollContainer
##   │   │   └── skill_tree_holder  ← Control; skill tree scene is added here
##   │   └── VBoxContainer  (info panel)
##   │       ├── skill_name_label   ← Label
##   │       ├── skill_desc_label   ← RichTextLabel
##   │       ├── rank_label         ← Label  ("Rank: 1 / 3")
##   │       ├── xp_threshold_label ← Label  ("Required XP: 1 500")
##   │       └── upgrade_button     ← Button
##   └── xp_label                   ← Label  ("XP: 750")
##
## The skill tree scene is instantiated at runtime so the same SkillMenuUI node
## can swap between multiple tree layouts (e.g. different skill categories).
extends Control
class_name SkillMenuUI

## PackedScene whose root has SkillTreeUI.gd. Instantiated into skill_tree_holder.
@export var skill_tree_scene : PackedScene

## Container that receives the instantiated skill tree scene.
@export var skill_tree_holder : Control

## Info-panel labels and widgets.
@export var skill_name_label      : Label
@export var skill_desc_label      : RichTextLabel
@export var rank_label            : Label
@export var xp_threshold_label    : Label
@export var upgrade_button        : Button
@export var xp_label              : Label

## Currently selected skill node (set when the player clicks a SkillNodeUI).
var _selected_node : SkillNodeUI = null

## Active SkillTreeUI instance.
var _skill_tree : SkillTreeUI = null


func _ready() -> void:
	PlayerProgression.xp_gained.connect(_on_xp_gained)
	PlayerProgression.skill_rank_changed.connect(_on_skill_rank_changed)

	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_pressed)
		upgrade_button.disabled = true

	_update_xp_label()

	if skill_tree_scene:
		_load_skill_tree(skill_tree_scene)


# ─── Public API ───────────────────────────────────────────────────────────────

## Swaps the active skill tree to a different scene (e.g. on tab change).
func load_skill_tree(scene : PackedScene) -> void:
	_load_skill_tree(scene)


# ─── Internal ─────────────────────────────────────────────────────────────────

func _load_skill_tree(scene : PackedScene) -> void:
	if not skill_tree_holder:
		push_warning("SkillMenuUI: skill_tree_holder is not assigned.")
		return

	# Remove any existing tree.
	for child in skill_tree_holder.get_children():
		child.queue_free()

	_skill_tree = scene.instantiate() as SkillTreeUI
	if not _skill_tree:
		push_warning("SkillMenuUI: skill_tree_scene root must have SkillTreeUI.gd attached.")
		return

	skill_tree_holder.add_child(_skill_tree)

	# Connect upgrade_requested from every SkillNodeUI.
	await get_tree().process_frame
	for node : SkillNodeUI in _skill_tree.skill_nodes:
		node.upgrade_requested.connect(_on_upgrade_requested)

	_clear_info_panel()


func _on_upgrade_requested(node : SkillNodeUI) -> void:
	_selected_node = node
	_refresh_info_panel()


func _on_upgrade_pressed() -> void:
	if not _selected_node or not _selected_node.associated_skill:
		return
	var skill_id : String = _selected_node.associated_skill.skill_id
	PlayerProgression.upgrade_skill(skill_id)
	# skill_rank_changed signal will trigger _on_skill_rank_changed below.


func _on_skill_rank_changed(skill_id : String, _new_rank : int) -> void:
	if _selected_node and _selected_node.associated_skill \
			and _selected_node.associated_skill.skill_id == skill_id:
		_refresh_info_panel()


func _on_xp_gained(_amount : int, _total : int) -> void:
	_update_xp_label()
	if _selected_node:
		_refresh_info_panel()


func _refresh_info_panel() -> void:
	if not _selected_node or not _selected_node.associated_skill:
		_clear_info_panel()
		return
	var def : SkillDefinition = _selected_node.associated_skill
	var rank : int = PlayerProgression.get_skill_rank(def.skill_id)
	var max_r : int = def.max_rank

	if skill_name_label:
		skill_name_label.text = def.skill_name
	if skill_desc_label:
		skill_desc_label.text = def.skill_description
	if rank_label:
		rank_label.text = "Rank: %d / %d" % [rank, max_r]

	if xp_threshold_label:
		if rank < max_r:
			var threshold : int = def.get_xp_threshold(rank)
			xp_threshold_label.text = "Required XP: %d" % threshold
		else:
			xp_threshold_label.text = "Max rank reached"

	if upgrade_button:
		upgrade_button.disabled = not PlayerProgression.can_upgrade_skill(def.skill_id)


func _clear_info_panel() -> void:
	if skill_name_label:
		skill_name_label.text = ""
	if skill_desc_label:
		skill_desc_label.text = ""
	if rank_label:
		rank_label.text = ""
	if xp_threshold_label:
		xp_threshold_label.text = ""
	if upgrade_button:
		upgrade_button.disabled = true


func _update_xp_label() -> void:
	if xp_label:
		xp_label.text = "XP: %d" % PlayerProgression.total_xp

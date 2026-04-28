## SkillTreeUI — container that wires SkillNodeUI buttons to PlayerProgression instances.
##
## Adapted from EveningComet/Godot-Skill-Tree SkillTree.gd (MIT).
##
## Attach this script to a Control node that contains SkillNodeUI descendants.
## The node hierarchy defines the skill layout and prerequisite relationships:
## a SkillNodeUI that is a direct child of another SkillNodeUI is treated as
## requiring the parent skill to be unlocked first (SkillNodeUI draws the
## connector Line2D automatically).
##
## SkillMenuUI instantiates a scene with this script via @export skill_tree_scene
## and calls setup() automatically. You can also use this script standalone by
## calling setup() from your own code after the scene tree is ready.
extends Control
class_name SkillTreeUI

## All SkillNodeUI nodes found recursively in this tree (populated in _ready()).
var skill_nodes : Array[SkillNodeUI] = []


func _ready() -> void:
	skill_nodes = _collect_skill_nodes(self)
	_wire_instances()
	PlayerProgression.skill_rank_changed.connect(_on_skill_rank_changed)
	PlayerProgression.xp_gained.connect(_on_xp_gained)


# ─── Public API ───────────────────────────────────────────────────────────────

## Re-evaluates which skill nodes should be enabled after any state change.
func refresh_all() -> void:
	for node : SkillNodeUI in skill_nodes:
		node._update_upgradability()


# ─── Internal ─────────────────────────────────────────────────────────────────

## Recursively collects every SkillNodeUI under branch.
func _collect_skill_nodes(branch : Control) -> Array[SkillNodeUI]:
	var found : Array[SkillNodeUI] = []
	for child in branch.get_children():
		if child is SkillNodeUI:
			found.append(child)
		if child is Control and child.get_child_count() > 0:
			found.append_array(_collect_skill_nodes(child))
	return found


## Matches each SkillNodeUI to its SkillInstance from PlayerProgression.
func _wire_instances() -> void:
	for node : SkillNodeUI in skill_nodes:
		if not node.associated_skill:
			push_warning("SkillTreeUI: SkillNodeUI has no associated_skill; skipping.")
			continue
		var instance : SkillInstance = PlayerProgression.get_skill_instance(
			node.associated_skill.skill_id
		)
		if not instance:
			push_warning("SkillTreeUI: no SkillInstance for skill_id '"
				+ node.associated_skill.skill_id
				+ "'. Is it registered in PlayerProgression.skills?")
			continue
		node.set_skill_instance(instance)


func _on_skill_rank_changed(_skill_id : String, _new_rank : int) -> void:
	refresh_all()


func _on_xp_gained(_amount : int, _total : int) -> void:
	refresh_all()

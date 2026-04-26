## ObjectiveEliminate — complete by killing a specific NPC or all enemies in a group.
##
## Assign the target NPC node directly, or use a group name to track all members.
extends ObjectiveBase
class_name ObjectiveEliminate

## Direct reference to the NPC node to eliminate (optional).
@export var target_npc : Node = null

## Group name — complete when all members of this group are dead (optional, overrides target_npc).
@export var target_group : String = ""

var _total : int = 0
var _killed : int = 0


func _on_activated() -> void:
	if not target_group.is_empty():
		var group_members : Array = get_tree().get_nodes_in_group(target_group)
		_total = group_members.size()
		for npc in group_members:
			var health : Node = npc.find_child("HealthAttribute", true, false)
			if health:
				health.attribute_reached_zero.connect(_on_npc_died.bind(npc))
		objective_progress_changed.emit(_killed, _total)
	elif target_npc:
		_total = 1
		var health : Node = target_npc.find_child("HealthAttribute", true, false)
		if health:
			health.attribute_reached_zero.connect(_on_npc_died.bind(target_npc))
		objective_progress_changed.emit(_killed, _total)


func _on_npc_died(_attribute_name, _current, _max, _npc : Node) -> void:
	_killed += 1
	objective_progress_changed.emit(_killed, _total)
	if _killed >= _total:
		complete()

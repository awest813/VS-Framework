## ObjectiveDocument — complete by interacting with a set number of objects.
##
## Tag interactable objects with the group "documentable" and wire their
## interact signal to document_one().
extends ObjectiveBase
class_name ObjectiveDocument

## How many objects must be documented.
@export var required_count : int = 3

var _documented : int = 0


func _on_activated() -> void:
	_documented = 0
	objective_progress_changed.emit(_documented, required_count)

	# Auto-wire any "documentable" nodes in the scene
	call_deferred("_wire_documentables")


func _wire_documentables() -> void:
	var targets : Array = get_tree().get_nodes_in_group("documentable")
	for target in targets:
		if target.has_signal("interact"):
			if not target.interact.is_connected(document_one):
				target.interact.connect(document_one)


## Call this when a documentable interactable is used.
func document_one(_unused = null) -> void:
	if not is_active or is_complete:
		return
	_documented += 1
	objective_progress_changed.emit(_documented, required_count)
	if _documented >= required_count:
		complete()

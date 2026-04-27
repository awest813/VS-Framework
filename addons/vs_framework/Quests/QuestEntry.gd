## QuestEntry — runtime mutable state of one quest instance.
##
## Created and owned by QuestManager. Not saved directly; QuestManager serialises
## the relevant fields into QuestSaveData on every change.
extends Resource
class_name QuestEntry

enum QuestStatus { AVAILABLE, ACTIVE, COMPLETED, FAILED }

## The definition this entry is an instance of.
var definition : QuestDefinition = null

## Current lifecycle status.
var status : QuestStatus = QuestStatus.AVAILABLE

## Generic progress counter (items collected, enemies killed, documents scanned, etc.).
var progress : int = 0

## True once the player has handed the quest in and received rewards.
var is_handed_in : bool = false


## Returns true if this quest is currently in the COMPLETED state.
func is_complete() -> bool:
	return status == QuestStatus.COMPLETED


## Returns true if this quest is currently in the FAILED state.
func is_failed() -> bool:
	return status == QuestStatus.FAILED


## Returns 0–1 progress fraction clamped to [0, 1].
func get_progress_fraction() -> float:
	if not definition:
		return 0.0
	var needed : int = _needed_for_completion()
	if needed <= 0:
		return 1.0
	return clamp(float(progress) / float(needed), 0.0, 1.0)


## Returns a display string like "2 / 5".
func get_progress_label() -> String:
	if not definition:
		return ""
	return str(progress) + " / " + str(_needed_for_completion())


# ─── Internal ─────────────────────────────────────────────────────────────────

func _needed_for_completion() -> int:
	if not definition:
		return 1
	match definition.objective_type:
		QuestDefinition.QuestObjectiveType.RETRIEVE_ITEM:
			return definition.target_item_quantity
		QuestDefinition.QuestObjectiveType.SURVIVE_DURATION:
			return int(definition.survive_duration)
		QuestDefinition.QuestObjectiveType.DOCUMENT_INTEL:
			return definition.document_count
		_:
			return 1

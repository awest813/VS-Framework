## ObjectiveFindExtraction — the extraction zone is hidden until objective completes.
##
## Wire this objective's objective_completed signal to ExtractionZone.open_zone().
## The extraction point position is revealed on the minimap once this objective completes.
extends ObjectiveBase
class_name ObjectiveFindExtraction

## The ExtractionZone to reveal when this objective completes.
@export var extraction_zone : ExtractionZone

## Another objective that must complete first.
@export var prerequisite_objective : ObjectiveBase


func _on_activated() -> void:
	if extraction_zone:
		extraction_zone.seal_zone()

	if prerequisite_objective:
		if not prerequisite_objective.objective_completed.is_connected(_on_prerequisite_done):
			prerequisite_objective.objective_completed.connect(_on_prerequisite_done)


func _on_prerequisite_done() -> void:
	complete()


func complete() -> void:
	super.complete()
	if extraction_zone:
		extraction_zone.open_zone()

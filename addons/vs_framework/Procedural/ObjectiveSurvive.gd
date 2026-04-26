## ObjectiveSurvive — complete by staying alive for a set duration.
extends ObjectiveBase
class_name ObjectiveSurvive

## Time in seconds the player must survive.
@export var survive_duration : float = 120.0

var _elapsed : float = 0.0


func _on_activated() -> void:
	_elapsed = 0.0


func _process(delta : float) -> void:
	if not is_active or is_complete:
		return

	_elapsed += delta
	var remaining : int = int(survive_duration - _elapsed)
	objective_progress_changed.emit(int(_elapsed), int(survive_duration))

	if _elapsed >= survive_duration:
		complete()

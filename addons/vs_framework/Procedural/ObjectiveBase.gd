## ObjectiveBase — base class for all objective components.
##
## Extend this class for each objective type. Place one on a node in the raid level.
extends Node
class_name ObjectiveBase

signal objective_completed
signal objective_failed
signal objective_progress_changed(current : int, total : int)

@export var objective_label : String = "Complete the objective"
@export var starts_active : bool = true

var is_complete : bool = false
var is_failed : bool = false
var is_active : bool = false


func _ready() -> void:
	if starts_active:
		activate()


## Activate this objective (call from mission setup or sequenced objectives).
func activate() -> void:
	is_active = true
	_on_activated()


func _on_activated() -> void:
	pass  # Override in subclass


## Mark the objective as complete.
func complete() -> void:
	if is_complete or is_failed:
		return
	is_complete = true
	is_active = false
	objective_completed.emit()
	CogitoGlobals.debug_log(true, "ObjectiveBase", objective_label + " — COMPLETED")


## Mark the objective as failed.
func fail() -> void:
	if is_complete or is_failed:
		return
	is_failed = true
	is_active = false
	objective_failed.emit()
	CogitoGlobals.debug_log(true, "ObjectiveBase", objective_label + " — FAILED")

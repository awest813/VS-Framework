## SourceIntegrationProfile — describes how an external project may inform VS Framework content.
extends Resource
class_name SourceIntegrationProfile

enum Priority { PRIMARY, SECONDARY, IMPLEMENTATION_REFERENCE, CONCEPT_ONLY, BLOCKED }
enum ReuseMode { CONTENT_DATA_FIRST, GODOT_NATIVE_ONLY, CONCEPT_ONLY, DO_NOT_USE }

## Human-readable source name.
@export var source_name : String = ""

## Upstream repository URL used for attribution and review.
@export var repository_url : String = ""

## Integration priority relative to other references.
@export var priority : Priority = Priority.SECONDARY

## How this source should be used by VS Framework integrations.
@export var reuse_mode : ReuseMode = ReuseMode.CONTENT_DATA_FIRST

## Short summary of what this source contributes.
@export_multiline var purpose : String = ""

## VS Framework modules that may consume ideas or data from this source.
@export var candidate_modules : Array[String] = []

## Direct code reuse is opt-in and should remain false unless license, engine, and duplication checks pass.
@export var allow_direct_code_reuse : bool = false

## Extra review notes for maintainers.
@export_multiline var review_notes : String = ""


func is_blocked() -> bool:
	return priority == Priority.BLOCKED or reuse_mode == ReuseMode.DO_NOT_USE


func can_use_content_data() -> bool:
	return not is_blocked() and reuse_mode != ReuseMode.CONCEPT_ONLY


func can_use_as_concept_reference() -> bool:
	return not is_blocked()


func can_reuse_code() -> bool:
	return allow_direct_code_reuse and not is_blocked() and reuse_mode == ReuseMode.GODOT_NATIVE_ONLY


func targets_module(module_name : String) -> bool:
	for target in candidate_modules:
		if target == module_name:
			return true
	return false


func get_priority_label() -> String:
	return Priority.keys()[priority].capitalize().replace("_", " ")


func get_reuse_mode_label() -> String:
	return ReuseMode.keys()[reuse_mode].capitalize().replace("_", " ")

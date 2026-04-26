## AnomalyComponent — extends hazard_zone behaviour with anomaly-specific logic.
##
## Place as a child of an Area3D node in your raid level.
## Requires an AnomalyDefinition resource to be assigned.
extends Area3D
class_name AnomalyComponent

signal artifact_spawned(artifact_item : Resource, position : Vector3)
signal detector_range_entered
signal detector_range_exited

## The anomaly type and behaviour definition.
@export var anomaly_definition : AnomalyDefinition

## Optional particle effect child node to play when active.
@export var particle_effect : GPUParticles3D

## Scene that wraps the artifact for dropping in the world.
@export var artifact_drop_scene : PackedScene

var _player_in_damage_zone : bool = false
var _player_in_detection_zone : bool = false
var _player_node : Node = null

# Inner sphere (damage) and outer sphere (detection) CollisionShapes
# are expected as children named "DamageShape" and "DetectionShape".
# If not present, a single CollisionShape on self is used for both.


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if anomaly_definition and particle_effect:
		particle_effect.emitting = true

	# Spawn artifact if chance roll succeeds
	if anomaly_definition and randf() < anomaly_definition.artifact_spawn_chance:
		_spawn_artifact()


func _process(delta : float) -> void:
	if not anomaly_definition or not _player_node:
		return

	if _player_in_damage_zone:
		_player_node.decrease_attribute(anomaly_definition.damage_attribute,
			anomaly_definition.damage_per_second * delta)

	# Feed detector item if player is in detection radius
	if _player_in_detection_zone and not _player_in_damage_zone:
		var detector : Node = _find_detector(_player_node)
		if detector and detector.has_method("ping"):
			detector.ping(global_position)


func _on_body_entered(body : Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	_player_node = body
	var dist : float = global_position.distance_to(body.global_position)
	var def : AnomalyDefinition = anomaly_definition

	if def and dist <= def.damage_radius:
		_player_in_damage_zone = true
	elif def and dist <= def.detection_radius:
		_player_in_detection_zone = true
		detector_range_entered.emit()


func _on_body_exited(body : Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	_player_in_damage_zone = false
	if _player_in_detection_zone:
		_player_in_detection_zone = false
		detector_range_exited.emit()
	_player_node = null


func _spawn_artifact() -> void:
	if not artifact_drop_scene or not anomaly_definition.artifact_item:
		return
	var instance : Node3D = artifact_drop_scene.instantiate() as Node3D
	if not instance:
		return
	# Try to assign the artifact item to the pickup component
	for child in instance.get_children():
		if child.has_method("set") and "slot_data" in child:
			child.slot_data.inventory_item = anomaly_definition.artifact_item
			break
	instance.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 0.05, randf_range(-0.5, 0.5))
	get_tree().current_scene.add_child(instance)
	artifact_spawned.emit(anomaly_definition.artifact_item, instance.global_position)


func _find_detector(player_node : Node) -> Node:
	# Look for a child of the player's interaction component named "AnomalyDetector"
	if player_node.has_method("find_child"):
		return player_node.find_child("AnomalyDetector", true, false)
	return null

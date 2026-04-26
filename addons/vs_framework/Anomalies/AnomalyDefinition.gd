## AnomalyDefinition — resource describing one anomaly type.
extends Resource
class_name AnomalyDefinition

enum AnomalyType { GRAVITATIONAL, ELECTRICAL, CHEMICAL, THERMAL }

@export var anomaly_type : AnomalyType = AnomalyType.GRAVITATIONAL
@export var display_name : String = "Anomaly"
@export_multiline var description : String = ""

## Attribute drained while the player is inside the damage radius.
@export var damage_attribute : String = "health"

## Damage per second applied inside the damage radius.
@export var damage_per_second : float = 10.0

## Radius in which the anomaly deals damage.
@export var damage_radius : float = 1.5

## Radius in which the detector item starts warning the player.
@export var detection_radius : float = 4.0

## 0–1 chance that an artifact is spawned at this anomaly's location.
@export_range(0.0, 1.0) var artifact_spawn_chance : float = 0.4

## Artifact item resource spawned if the chance roll succeeds.
@export var artifact_item : Resource  # ArtifactItemPD

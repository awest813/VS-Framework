## ArtifactModifier — a single attribute change entry used by ArtifactItemPD.
extends Resource
class_name ArtifactModifier

## Name of the COGITO attribute to affect (e.g. "health", "stamina").
@export var attribute_name : String = ""

## Change per second (positive = buff, negative = debuff).
@export var delta_per_second : float = 0.0

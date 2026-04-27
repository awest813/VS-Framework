## PlayerProgressionSaveData — persisted snapshot of XP and unlocked skills.
extends Resource
class_name PlayerProgressionSaveData

## Total XP accumulated across all runs.
@export var total_xp : int = 0

## IDs of skills the player has unlocked.
@export var unlocked_skill_ids : Array[String] = []

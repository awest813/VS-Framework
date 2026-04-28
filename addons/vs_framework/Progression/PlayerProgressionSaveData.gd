## PlayerProgressionSaveData — persisted snapshot of XP and unlocked skills.
##
## skill_ranks is the primary store: {skill_id: rank} for all skills at rank ≥ 1.
## unlocked_skill_ids is kept for migration from saves made before ranked skills
## were introduced; PlayerProgression promotes any listed id to rank 1 on load.
extends Resource
class_name PlayerProgressionSaveData

## Total XP accumulated across all runs.
@export var total_xp : int = 0

## Current skill ranks keyed by skill_id (only entries with rank ≥ 1 are stored).
@export var skill_ranks : Dictionary = {}

## Legacy list of unlocked skill ids. Used only for migrating old saves.
@export var unlocked_skill_ids : Array[String] = []

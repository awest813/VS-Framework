## QuestSaveData — persisted snapshot of all quest states.
extends Resource
class_name QuestSaveData

## Serialised per-quest state. Each dict: {quest_id, status, progress, is_handed_in}.
@export var quest_states : Array[Dictionary] = []

## IDs of quests that have been completed at least once (used to hide non-repeatable quests).
@export var completed_quest_ids : Array[String] = []

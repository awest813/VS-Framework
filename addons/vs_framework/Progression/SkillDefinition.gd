## SkillDefinition — resource describing one unlockable player skill or perk.
##
## Create .tres files for each skill. Assign them to PlayerProgression.skills.
##
## Single-rank skills: leave tiers empty. attribute_max_bonus and
## attribute_rate_multiplier apply on unlock (rank 1) and max_rank = 1.
##
## Multi-rank skills: populate the tiers array with one SkillTier per rank.
##   tiers[0] = rank 1 data, tiers[1] = rank 2 data, etc.
## Each tier overrides attribute_max_bonus and attribute_rate_multiplier for
## that rank. max_rank equals tiers.size(). The XP threshold to reach rank 1
## is always xp_required; thresholds for rank 2+ come from SkillTier.xp_threshold.
##
## Job/class-based skill gating is intentionally omitted; see
## EveningComet/Godot-Skill-Tree (MIT) for the concept reference.
extends Resource
class_name SkillDefinition

## Unique identifier (no spaces). Used as a key throughout the system.
@export var skill_id : String = ""

## Display name shown in the skill tree UI.
@export var skill_name : String = ""

## Short tooltip description.
@export_multiline var skill_description : String = ""

## Whether this skill runs continuously (true) or must be manually activated (false).
@export var is_passive : bool = true

## Minimum total XP the player must have to unlock this skill (rank 0 → rank 1).
@export var xp_required : int = 500

## IDs of skills that must be at rank ≥ 1 before this one can be unlocked.
@export var prerequisite_skill_ids : Array[String] = []

## COGITO attribute name this skill improves (e.g. "health", "stamina").
## Leave empty for skills that are checked programmatically instead.
@export var attribute_name : String = ""

## Flat bonus added to the COGITO attribute maximum.
## Used directly for single-rank skills; multi-rank skills use the active tier's value.
@export var attribute_max_bonus : float = 0.0

## Multiplier applied to the attribute's decay / accumulation rate (1.0 = no change).
## E.g. 0.8 on hunger means the player gets hungry 20% slower.
## Used directly for single-rank skills; multi-rank skills use the active tier's value.
@export var attribute_rate_multiplier : float = 1.0

## Per-rank tier data. Leave empty for a single-rank (binary unlock) skill.
## tiers[0] holds rank 1 bonuses, tiers[1] rank 2 bonuses, etc.
@export var tiers : Array[SkillTier] = []

## Maximum rank this skill can reach. Returns 1 for single-rank skills.
var max_rank : int:
	get: return max(1, tiers.size())


## Returns the attribute_max_bonus effective at the given rank (1-based).
## Falls back to the top-level attribute_max_bonus for single-rank skills.
func get_bonus_at_rank(rank : int) -> float:
	if tiers.is_empty() or rank < 1:
		return attribute_max_bonus
	return tiers[mini(rank, tiers.size()) - 1].attribute_max_bonus


## Returns the attribute_rate_multiplier effective at the given rank (1-based).
## Falls back to the top-level attribute_rate_multiplier for single-rank skills.
func get_rate_multiplier_at_rank(rank : int) -> float:
	if tiers.is_empty() or rank < 1:
		return attribute_rate_multiplier
	return tiers[mini(rank, tiers.size()) - 1].attribute_rate_multiplier


## Returns the minimum total XP needed to advance from from_rank to from_rank + 1.
## from_rank 0 → 1 uses xp_required; higher ranks use the corresponding SkillTier.
func get_xp_threshold(from_rank : int) -> int:
	if from_rank == 0:
		return xp_required
	if from_rank < tiers.size():
		return tiers[from_rank].xp_threshold
	return 0

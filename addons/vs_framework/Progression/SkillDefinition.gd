## SkillDefinition — resource describing one unlockable player skill or perk.
##
## Create .tres files for each skill. Assign them to PlayerProgression.skills.
extends Resource
class_name SkillDefinition

## Unique identifier (no spaces). Used as a key throughout the system.
@export var skill_id : String = ""

## Display name shown in the skill tree UI.
@export var skill_name : String = ""

## Short tooltip description.
@export_multiline var skill_description : String = ""

## Total XP required for the player to unlock this skill.
@export var xp_required : int = 500

## IDs of skills that must be unlocked before this one is available.
@export var prerequisite_skill_ids : Array[String] = []

## Attribute name this skill improves (e.g. "health", "stamina").
## Leave empty for skills that are checked programmatically instead.
@export var attribute_name : String = ""

## Flat value added to the attribute's maximum when this skill is unlocked.
@export var attribute_max_bonus : float = 0.0

## Multiplier applied to the attribute's decay / accumulation rate (1.0 = no change).
## E.g. 0.8 on hunger means the player gets hungry 20% slower.
@export var attribute_rate_multiplier : float = 1.0

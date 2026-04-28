## SkillInstance — lightweight runtime wrapper that tracks the current rank of one SkillDefinition.
##
## PlayerProgression creates one SkillInstance per registered skill on startup.
## Listen to rank_changed to react to upgrades and downgrades
## (e.g. apply or remove COGITO attribute bonuses).
##
## Adapted from EveningComet/Godot-Skill-Tree (MIT).
extends RefCounted
class_name SkillInstance

## Emitted when this skill's rank changes. The instance itself is passed so
## listeners can read the new curr_rank and the associated SkillDefinition.
signal rank_changed(instance : SkillInstance)

## The definition this instance is tracking.
var skill : SkillDefinition

## Current rank. 0 = not yet unlocked; max = skill.max_rank.
## rank_changed is emitted on any assignment so that direct rank restoration
## (e.g. during save-load) and upgrade()/downgrade() all behave consistently.
var curr_rank : int = 0:
	get: return curr_rank
	set(value):
		curr_rank = clampi(value, 0, skill.max_rank)
		rank_changed.emit(self)


func _init(definition : SkillDefinition) -> void:
	skill = definition


## Returns true when this skill is at its maximum rank.
func is_max_rank() -> bool:
	return curr_rank >= skill.max_rank


## Increments rank by one (rank_changed is emitted by the setter).
func upgrade() -> void:
	curr_rank += 1


## Decrements rank by one (rank_changed is emitted by the setter).
func downgrade() -> void:
	curr_rank -= 1

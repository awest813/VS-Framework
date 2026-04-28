## SkillTier — describes the bonuses granted at a specific rank of a SkillDefinition.
##
## Add one SkillTier per rank to SkillDefinition.tiers:
##   tiers[0] = rank 1 data, tiers[1] = rank 2 data, etc.
##
## The XP threshold to reach rank N (N ≥ 2) is tiers[N-1].xp_threshold.
## Rank 1 (initial unlock) always uses SkillDefinition.xp_required.
##
## Adapted from EveningComet/Godot-Skill-Tree (MIT).
extends Resource
class_name SkillTier

## Minimum total XP needed to upgrade into this tier.
## Ignored for tiers[0] (rank 1 data); rank 1 uses SkillDefinition.xp_required.
@export var xp_threshold : int = 1000

## Flat value added to the COGITO attribute maximum at this rank.
## Overrides SkillDefinition.attribute_max_bonus for multi-rank skills.
@export var attribute_max_bonus : float = 0.0

## Multiplier applied to the COGITO attribute decay/accumulation rate at this rank.
## Overrides SkillDefinition.attribute_rate_multiplier for multi-rank skills.
@export var attribute_rate_multiplier : float = 1.0

## General power scale factor for use in active skill logic (e.g. damage multiplier).
@export var power_scale : float = 1.0

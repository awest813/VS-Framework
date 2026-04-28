## PlayerProgression — autoload that tracks XP, levels, and ranked skill unlocks.
##
## XP is awarded by QuestManager (quest completion), ExtractionLoopManager
## (successful extractions), and any other game code via add_xp().
##
## Skills are defined as SkillDefinition resources. Register them in the
## skills export array. The player can upgrade skills whose prerequisites are
## satisfied and whose XP threshold is met.
##
## Single-rank skills behave exactly as before (binary locked/unlocked).
## Multi-rank skills (SkillDefinition.tiers populated) advance one rank at a
## time; each rank has its own XP threshold in SkillTier.xp_threshold.
##
## Wire skill_rank_changed to your skill-tree UI and to player attribute nodes
## so bonuses take effect immediately.
extends Node

signal xp_gained(amount : int, total_xp : int)
signal skill_unlocked(skill_id : String)          # emitted at rank 1 for backward compat
signal skill_rank_changed(skill_id : String, new_rank : int)
signal level_up(new_level : int)

const SAVE_PATH : String = "user://vs_progression.res"

## XP required to advance each level (index 0 = level 1→2, index 1 = level 2→3, etc.).
## The last value repeats for all higher levels.
@export var xp_per_level : Array[int] = [500, 1000, 2000, 3500, 5000]

## All SkillDefinition resources available in the game. Assign in the editor.
@export var skills : Array[SkillDefinition] = []

## Current total XP (accumulates indefinitely; levels are derived from it).
var total_xp : int = 0

## Current player level (derived; not stored separately — computed from total_xp).
var current_level : int = 1

## Runtime SkillInstance for each registered skill, keyed by skill_id.
var _instances : Dictionary = {}  # skill_id → SkillInstance


func _ready() -> void:
	_build_instances()
	_load()
	current_level = _compute_level()


# ─── Public API ───────────────────────────────────────────────────────────────

## Awards XP and checks for level-up. Call from quest completion, extraction, etc.
func add_xp(amount : int) -> void:
	if amount <= 0:
		return
	var prev_level : int = current_level
	total_xp += amount
	current_level = _compute_level()
	xp_gained.emit(amount, total_xp)
	if current_level > prev_level:
		level_up.emit(current_level)
		CogitoGlobals.debug_log(true, "PlayerProgression", "Level up → " + str(current_level))
	_save()


## Attempts to upgrade the given skill by one rank.
## For a single-rank skill this is equivalent to the old unlock_skill().
## Returns false if prerequisites are missing, the skill is already at max rank,
## or the player's total XP is below the threshold for the next rank.
func upgrade_skill(skill_id : String) -> bool:
	var def : SkillDefinition = get_skill(skill_id)
	if not def:
		push_warning("PlayerProgression: unknown skill id: " + skill_id)
		return false
	var instance : SkillInstance = get_skill_instance(skill_id)
	if not instance:
		return false
	if instance.is_max_rank():
		CogitoGlobals.debug_log(true, "PlayerProgression",
			"Upgrade blocked: " + skill_id + " is already at max rank.")
		return false
	# Prerequisites are only checked for the initial unlock (rank 0 → 1).
	if instance.curr_rank == 0:
		for prereq : String in def.prerequisite_skill_ids:
			if not is_skill_unlocked(prereq):
				CogitoGlobals.debug_log(true, "PlayerProgression",
					"Upgrade blocked: prerequisite " + prereq + " not met.")
				return false
	var threshold : int = def.get_xp_threshold(instance.curr_rank)
	if total_xp < threshold:
		CogitoGlobals.debug_log(true, "PlayerProgression",
			"Upgrade blocked: need " + str(threshold) + " XP, have " + str(total_xp))
		return false
	instance.upgrade()
	skill_rank_changed.emit(skill_id, instance.curr_rank)
	if instance.curr_rank == 1:
		skill_unlocked.emit(skill_id)
		CogitoGlobals.debug_log(true, "PlayerProgression", "Skill unlocked: " + skill_id)
	else:
		CogitoGlobals.debug_log(true, "PlayerProgression",
			"Skill " + skill_id + " upgraded to rank " + str(instance.curr_rank))
	_save()
	return true


## Backward-compatible alias for upgrade_skill(). Returns false if the skill is
## already unlocked (rank ≥ 1). Prefer upgrade_skill() in new code.
func unlock_skill(skill_id : String) -> bool:
	if is_skill_unlocked(skill_id):
		return false
	return upgrade_skill(skill_id)


## Returns true if the given skill has been unlocked (rank ≥ 1).
func is_skill_unlocked(skill_id : String) -> bool:
	return get_skill_rank(skill_id) >= 1


## Returns the current rank of a skill (0 = not yet unlocked).
func get_skill_rank(skill_id : String) -> int:
	var instance : SkillInstance = get_skill_instance(skill_id)
	if not instance:
		return 0
	return instance.curr_rank


## Returns true if the player meets all requirements to upgrade the skill by one rank.
func can_upgrade_skill(skill_id : String) -> bool:
	var def : SkillDefinition = get_skill(skill_id)
	if not def:
		return false
	var instance : SkillInstance = get_skill_instance(skill_id)
	if not instance or instance.is_max_rank():
		return false
	if instance.curr_rank == 0:
		for prereq : String in def.prerequisite_skill_ids:
			if not is_skill_unlocked(prereq):
				return false
	return total_xp >= def.get_xp_threshold(instance.curr_rank)


## Returns the SkillInstance for a given skill id, or null.
func get_skill_instance(skill_id : String) -> SkillInstance:
	if skill_id in _instances:
		return _instances[skill_id]
	return null


## Returns the SkillDefinition for a given id, or null.
func get_skill(skill_id : String) -> SkillDefinition:
	for def in skills:
		if def.skill_id == skill_id:
			return def
	return null


## Returns all skills that can be upgraded by one rank right now
## (prerequisites met, XP threshold satisfied, not yet at max rank).
func get_upgradable_skills() -> Array[SkillDefinition]:
	var result : Array[SkillDefinition] = []
	for def in skills:
		if can_upgrade_skill(def.skill_id):
			result.append(def)
	return result


## Deprecated: returns unlockable skills (rank 0, prerequisites met, XP sufficient).
## Prefer get_upgradable_skills() in new code.
func get_unlockable_skills() -> Array[SkillDefinition]:
	var result : Array[SkillDefinition] = []
	for def in get_upgradable_skills():
		if get_skill_rank(def.skill_id) == 0:
			result.append(def)
	return result


## Returns XP needed to reach the next level (0 if already at max tracked level).
func xp_to_next_level() -> int:
	var xp_for_current : int = _xp_for_level(current_level)
	var xp_for_next : int = _xp_for_level(current_level + 1)
	return max(xp_for_next - total_xp, 0)


## Returns a 0–1 fraction of progress toward the next level.
func level_progress_fraction() -> float:
	var xp_start : int = _xp_for_level(current_level)
	var xp_end : int = _xp_for_level(current_level + 1)
	var span : int = xp_end - xp_start
	if span <= 0:
		return 1.0
	return clamp(float(total_xp - xp_start) / float(span), 0.0, 1.0)


# ─── Internal ─────────────────────────────────────────────────────────────────

func _build_instances() -> void:
	_instances.clear()
	for def in skills:
		if def.skill_id.is_empty():
			push_warning("PlayerProgression: SkillDefinition has empty skill_id; skipping.")
			continue
		_instances[def.skill_id] = SkillInstance.new(def)


func _compute_level() -> int:
	var lv : int = 1
	while total_xp >= _xp_for_level(lv + 1):
		lv += 1
	return lv


func _xp_for_level(lv : int) -> int:
	## Returns the cumulative XP needed to reach `lv` from level 1.
	if lv <= 1:
		return 0
	var cumulative : int = 0
	for i in lv - 1:
		var idx : int = min(i, xp_per_level.size() - 1)
		cumulative += xp_per_level[idx]
	return cumulative


func _save() -> void:
	var res := PlayerProgressionSaveData.new()
	res.total_xp = total_xp
	var ranks : Dictionary = {}
	for skill_id : String in _instances:
		var instance : SkillInstance = _instances[skill_id]
		if instance.curr_rank > 0:
			ranks[skill_id] = instance.curr_rank
	res.skill_ranks = ranks
	ResourceSaver.save(res, SAVE_PATH)


func _load() -> void:
	if not ResourceLoader.exists(SAVE_PATH):
		return
	var res : Resource = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not res or not res is PlayerProgressionSaveData:
		return
	total_xp = res.total_xp
	# Restore ranks from the primary skill_ranks dict.
	for skill_id : String in res.skill_ranks:
		if skill_id in _instances:
			_instances[skill_id].curr_rank = res.skill_ranks[skill_id]
	# Migrate legacy saves: promote any listed id to rank 1 if not already ranked.
	for skill_id : String in res.unlocked_skill_ids:
		if skill_id in _instances and _instances[skill_id].curr_rank == 0:
			_instances[skill_id].curr_rank = 1

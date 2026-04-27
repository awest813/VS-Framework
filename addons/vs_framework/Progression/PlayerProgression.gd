## PlayerProgression — autoload that tracks XP and manages skill unlocks.
##
## XP is awarded by QuestManager (quest completion), ExtractionLoopManager
## (successful extractions), and any other game code via add_xp().
##
## Skills are defined as SkillDefinition resources. Register them in the
## skills export array. The player can spend XP to unlock skills whose
## prerequisites are satisfied.
##
## Wire skill_unlocked to your skill-tree UI and to player attribute nodes
## so bonuses take effect immediately.
extends Node

signal xp_gained(amount : int, total_xp : int)
signal skill_unlocked(skill_id : String)
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

## Set of unlocked skill ids.
var _unlocked : Array[String] = []


func _ready() -> void:
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


## Attempts to unlock a skill. Returns false if prerequisites are missing or
## already unlocked or the player does not have enough XP.
func unlock_skill(skill_id : String) -> bool:
	if is_skill_unlocked(skill_id):
		return false
	var def : SkillDefinition = get_skill(skill_id)
	if not def:
		push_warning("PlayerProgression: unknown skill id: " + skill_id)
		return false
	for prereq : String in def.prerequisite_skill_ids:
		if not is_skill_unlocked(prereq):
			CogitoGlobals.debug_log(true, "PlayerProgression",
				"Unlock blocked: prerequisite " + prereq + " not met.")
			return false
	if total_xp < def.xp_required:
		CogitoGlobals.debug_log(true, "PlayerProgression",
			"Unlock blocked: need " + str(def.xp_required) + " XP, have " + str(total_xp))
		return false
	_unlocked.append(skill_id)
	skill_unlocked.emit(skill_id)
	CogitoGlobals.debug_log(true, "PlayerProgression", "Skill unlocked: " + skill_id)
	_save()
	return true


## Returns true if the given skill has been unlocked.
func is_skill_unlocked(skill_id : String) -> bool:
	return skill_id in _unlocked


## Returns the SkillDefinition for a given id, or null.
func get_skill(skill_id : String) -> SkillDefinition:
	for def in skills:
		if def.skill_id == skill_id:
			return def
	return null


## Returns all skills that are currently available to unlock
## (prerequisites met, not yet unlocked, XP sufficient).
func get_unlockable_skills() -> Array[SkillDefinition]:
	var result : Array[SkillDefinition] = []
	for def in skills:
		if is_skill_unlocked(def.skill_id):
			continue
		if total_xp < def.xp_required:
			continue
		var prereqs_met : bool = true
		for prereq : String in def.prerequisite_skill_ids:
			if not is_skill_unlocked(prereq):
				prereqs_met = false
				break
		if prereqs_met:
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
	res.unlocked_skill_ids = _unlocked.duplicate()
	ResourceSaver.save(res, SAVE_PATH)


func _load() -> void:
	if not ResourceLoader.exists(SAVE_PATH):
		return
	var res : Resource = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not res or not res is PlayerProgressionSaveData:
		return
	total_xp = res.total_xp
	_unlocked = res.unlocked_skill_ids.duplicate()

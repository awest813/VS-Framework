## QuestManager — autoload that tracks all quest states and persists them.
##
## Register all QuestDefinition resources in the quest_definitions export array
## (editor or at runtime). Wire signals to your mission board, HUD, and in-game
## objective trackers.
##
## Progress signals can be fired by game code:
##   QuestManager.advance_progress("kill_bandits", 1)   # killed one bandit
##   QuestManager.complete_quest("kill_bandits")         # override completion
extends Node

signal quest_accepted(quest_id : String)
signal quest_progress_updated(quest_id : String, progress : int)
signal quest_completed(quest_id : String)
signal quest_failed(quest_id : String)
signal quest_handed_in(quest_id : String)

const SAVE_PATH : String = "user://vs_quests.res"

## All QuestDefinition resources known to the game. Assign in the editor.
@export var quest_definitions : Array[QuestDefinition] = []

## Runtime map of quest_id → QuestEntry.
var _entries : Dictionary = {}

## IDs of quests completed at least once (prevents re-offer of non-repeatable quests).
var _completed_ids : Array[String] = []


func _ready() -> void:
	_load()
	# Initialise entries for any definition not yet in the save file.
	for def in quest_definitions:
		if not _entries.has(def.quest_id):
			var entry := QuestEntry.new()
			entry.definition = def
			entry.status = QuestEntry.QuestStatus.AVAILABLE
			_entries[def.quest_id] = entry
		else:
			# Reattach the live definition reference (not stored in the save).
			_entries[def.quest_id].definition = def


# ─── Public API ───────────────────────────────────────────────────────────────

## Accepts a quest by id. Moves it to ACTIVE and emits quest_accepted.
## Returns false if the quest is not available or does not exist.
func accept_quest(quest_id : String) -> bool:
	var entry : QuestEntry = _get_entry(quest_id)
	if not entry:
		push_warning("QuestManager: unknown quest id: " + quest_id)
		return false
	if entry.status != QuestEntry.QuestStatus.AVAILABLE:
		return false
	entry.status = QuestEntry.QuestStatus.ACTIVE
	entry.progress = 0
	entry.is_handed_in = false
	_save()
	quest_accepted.emit(quest_id)
	CogitoGlobals.debug_log(true, "QuestManager", "Quest accepted: " + quest_id)
	return true


## Advances the generic progress counter on an active quest.
## Automatically completes the quest when the needed threshold is reached.
func advance_progress(quest_id : String, amount : int = 1) -> void:
	var entry : QuestEntry = _get_entry(quest_id)
	if not entry or entry.status != QuestEntry.QuestStatus.ACTIVE:
		return
	entry.progress += amount
	quest_progress_updated.emit(quest_id, entry.progress)
	_check_auto_completion(entry)
	_save()


## Forcefully completes a quest and grants all rewards. Idempotent.
func complete_quest(quest_id : String) -> void:
	var entry : QuestEntry = _get_entry(quest_id)
	if not entry or entry.status == QuestEntry.QuestStatus.COMPLETED:
		return
	entry.status = QuestEntry.QuestStatus.COMPLETED
	if not _completed_ids.has(quest_id):
		_completed_ids.append(quest_id)
	_grant_rewards(entry.definition)
	_save()
	quest_completed.emit(quest_id)
	CogitoGlobals.debug_log(true, "QuestManager", "Quest completed: " + quest_id)


## Marks the quest as handed in (reward animation / confirmation step).
## Call from your quest-board UI after showing the reward screen.
func hand_in_quest(quest_id : String) -> void:
	var entry : QuestEntry = _get_entry(quest_id)
	if not entry or entry.status != QuestEntry.QuestStatus.COMPLETED:
		return
	entry.is_handed_in = true
	if entry.definition and entry.definition.is_repeatable:
		entry.status = QuestEntry.QuestStatus.AVAILABLE
		entry.progress = 0
	_save()
	quest_handed_in.emit(quest_id)


## Marks a quest as failed and applies the faction reputation penalty.
func fail_quest(quest_id : String) -> void:
	var entry : QuestEntry = _get_entry(quest_id)
	if not entry or entry.status == QuestEntry.QuestStatus.FAILED:
		return
	entry.status = QuestEntry.QuestStatus.FAILED
	_apply_fail_penalty(entry.definition)
	_save()
	quest_failed.emit(quest_id)
	CogitoGlobals.debug_log(true, "QuestManager", "Quest failed: " + quest_id)


## Returns the QuestEntry for quest_id, or null if not found.
func get_entry(quest_id : String) -> QuestEntry:
	return _get_entry(quest_id)


## Returns all ACTIVE quest entries.
func get_active_quests() -> Array[QuestEntry]:
	var result : Array[QuestEntry] = []
	for entry : QuestEntry in _entries.values():
		if entry.status == QuestEntry.QuestStatus.ACTIVE:
			result.append(entry)
	return result


## Returns all AVAILABLE quest entries (excluding completed non-repeatable quests).
func get_available_quests() -> Array[QuestEntry]:
	var result : Array[QuestEntry] = []
	for entry : QuestEntry in _entries.values():
		if entry.status != QuestEntry.QuestStatus.AVAILABLE:
			continue
		if entry.definition and _completed_ids.has(entry.definition.quest_id):
			if not entry.definition.is_repeatable:
				continue
		result.append(entry)
	return result


## Returns all COMPLETED (but not yet handed-in) quest entries.
func get_completed_quests() -> Array[QuestEntry]:
	var result : Array[QuestEntry] = []
	for entry : QuestEntry in _entries.values():
		if entry.status == QuestEntry.QuestStatus.COMPLETED and not entry.is_handed_in:
			result.append(entry)
	return result


## Returns true if the named quest has ever been completed.
func has_completed(quest_id : String) -> bool:
	return quest_id in _completed_ids


# ─── Internal ─────────────────────────────────────────────────────────────────

func _get_entry(quest_id : String) -> QuestEntry:
	return _entries.get(quest_id, null)


func _check_auto_completion(entry : QuestEntry) -> void:
	if not entry.definition:
		return
	var def : QuestDefinition = entry.definition
	var needed : int = 1
	match def.objective_type:
		QuestDefinition.QuestObjectiveType.RETRIEVE_ITEM:
			needed = def.target_item_quantity
		QuestDefinition.QuestObjectiveType.SURVIVE_DURATION:
			needed = int(def.survive_duration)
		QuestDefinition.QuestObjectiveType.DOCUMENT_INTEL:
			needed = def.document_count
		_:
			needed = 1
	if entry.progress >= needed:
		complete_quest(def.quest_id)


func _grant_rewards(def : QuestDefinition) -> void:
	if not def:
		return
	var stash : Node = get_node_or_null("/root/PersistentStashManager")
	if stash and def.reward_currency > 0:
		stash.commit_extraction([], def.reward_currency)

	if FactionRegistry and not def.giver_faction_id.is_empty() and def.reward_reputation > 0:
		FactionRegistry.change_reputation(def.giver_faction_id, def.reward_reputation)

	var prog : Node = get_node_or_null("/root/PlayerProgression")
	if prog and def.reward_xp > 0 and prog.has_method("add_xp"):
		prog.add_xp(def.reward_xp)


func _apply_fail_penalty(def : QuestDefinition) -> void:
	if not def:
		return
	if FactionRegistry and not def.giver_faction_id.is_empty() and def.fail_reputation_loss > 0:
		FactionRegistry.change_reputation(def.giver_faction_id, -def.fail_reputation_loss)


func _save() -> void:
	var res := QuestSaveData.new()
	for quest_id : String in _entries:
		var entry : QuestEntry = _entries[quest_id]
		res.quest_states.append({
			"quest_id": quest_id,
			"status": entry.status,
			"progress": entry.progress,
			"is_handed_in": entry.is_handed_in,
		})
	res.completed_quest_ids = _completed_ids.duplicate()
	ResourceSaver.save(res, SAVE_PATH)


func _load() -> void:
	if not ResourceLoader.exists(SAVE_PATH):
		return
	var res : Resource = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not res or not res is QuestSaveData:
		return
	_completed_ids = res.completed_quest_ids.duplicate()
	for state : Dictionary in res.quest_states:
		var quest_id : String = state.get("quest_id", "")
		if quest_id.is_empty():
			continue
		var entry := QuestEntry.new()
		entry.status = state.get("status", QuestEntry.QuestStatus.AVAILABLE)
		entry.progress = state.get("progress", 0)
		entry.is_handed_in = state.get("is_handed_in", false)
		_entries[quest_id] = entry

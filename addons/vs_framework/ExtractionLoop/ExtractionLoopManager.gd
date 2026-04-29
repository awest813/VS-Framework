## ExtractionLoopManager — autoload that owns the hub-and-spoke run loop.
##
## Phase flow:
##   HUB → MISSION_SELECT → DEPLOY → IN_RAID → EXTRACTING → DEBRIEF → HUB
##
## Wire up signals and call the public API from your Hub scene, MissionBoard UI,
## ExtractionZone, and DebriefScene.
extends Node

signal phase_changed(new_phase : int)
signal raid_started(session : RunSessionResource)
signal raid_extraction_started
signal raid_ended_success(session : RunSessionResource)
signal raid_ended_death(session : RunSessionResource)
signal debrief_closed

enum Phase {
	HUB,
	MISSION_SELECT,
	DEPLOY,
	IN_RAID,
	EXTRACTING,
	DEBRIEF,
}

## Current phase of the loop.
var current_phase : Phase = Phase.HUB

## Active run session. Valid while IN_RAID or EXTRACTING.
var active_session : RunSessionResource = null

## Path of the hub scene to return to after debrief.
@export var hub_scene_path : String = ""

## Path of the debrief scene to load on extraction.
@export var debrief_scene_path : String = ""

## Reference to the PersistentStashManager sibling/autoload.
var stash_manager : PersistentStashManager = null


func _ready() -> void:
	stash_manager = get_node_or_null("/root/PersistentStashManager")
	if not stash_manager:
		push_warning("ExtractionLoopManager: PersistentStashManager autoload not found.")


# ─── Public API ───────────────────────────────────────────────────────────────

## Call from the Mission Board when the player accepts a mission.
## Pass the MissionDefinitionResource (or its id string) to record it.
func select_mission(mission_id : String) -> void:
	_set_phase(Phase.MISSION_SELECT)
	if not active_session:
		active_session = RunSessionResource.new()
	active_session.mission_id = mission_id


## Call when the player confirms deployment (e.g. presses "Deploy" button).
## Pass the player's current stash inventory_slots array for the pre-raid snapshot.
func deploy(stash_slots : Array = []) -> void:
	if current_phase != Phase.MISSION_SELECT:
		var phase_name : String = _get_phase_name(current_phase)
		var message : String = "ExtractionLoopManager: deploy() called in phase %s instead of MISSION_SELECT." % phase_name
		push_warning(message)
		return
	if not active_session:
		active_session = RunSessionResource.new()
	active_session.wipe()
	active_session.snapshot_stash(stash_slots)
	_set_phase(Phase.DEPLOY)
	# Actual scene loading is done by the caller using CogitoSceneManager.
	# Emit so the Hub UI can trigger the load.
	_set_phase(Phase.IN_RAID)
	raid_started.emit(active_session)


## Call when the player reaches an ExtractionZone and extraction is confirmed.
func begin_extraction() -> void:
	if current_phase != Phase.IN_RAID:
		return
	_set_phase(Phase.EXTRACTING)
	raid_extraction_started.emit()


## Call once the extraction cutscene / timer is complete with the items
## and currency the player is bringing out.
func complete_extraction(extracted_items : Array[Dictionary], earned_currency : int) -> void:
	if current_phase != Phase.EXTRACTING:
		return
	raid_ended_success.emit(active_session)
	if stash_manager:
		stash_manager.commit_extraction(extracted_items, earned_currency)
	_set_phase(Phase.DEBRIEF)


## Call when the player dies during a raid.
func player_died() -> void:
	if current_phase not in [Phase.IN_RAID, Phase.EXTRACTING]:
		return
	if active_session:
		active_session.is_alive = false
	raid_ended_death.emit(active_session)
	active_session = null
	_set_phase(Phase.DEBRIEF)


## Call from the DebriefScene when the player closes the debrief screen.
func close_debrief() -> void:
	debrief_closed.emit()
	active_session = null
	_set_phase(Phase.HUB)


## Updates elapsed raid time. Call this from a scene's _process if you want time tracking.
func tick_raid_time(delta : float) -> void:
	if active_session and current_phase == Phase.IN_RAID:
		active_session.elapsed_time += delta


# ─── Internal ─────────────────────────────────────────────────────────────────

func _set_phase(new_phase : Phase) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)
	CogitoGlobals.debug_log(true, "ExtractionLoopManager", "Phase → " + _get_phase_name(new_phase))


func _get_phase_name(phase : int) -> String:
	var phase_names := Phase.keys()
	if phase >= 0 and phase < phase_names.size():
		return phase_names[phase]
	return "UNKNOWN"

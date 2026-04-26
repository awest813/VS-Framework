## DemoRaidZone — wires all VS Framework raid systems for the demo level.
##
## Attach to the root of a raid scene. Assign the mission resource, and the
## script will auto-generate the room layout, spawn enemies, and set up objectives.
extends Node3D
class_name DemoRaidZone

@export var mission_definition : MissionDefinitionResource

@export var ai_director : AIDirector
@export var room_activity_system : RoomActivitySystem
@export var emission_event : EmissionEvent
@export var extraction_zone : ExtractionZone
@export var minimap : MinimapSystem
@export var raid_hud : RaidHUDExtension
@export var death_screen : RaidDeathScreen


func _ready() -> void:
	if not mission_definition:
		push_warning("DemoRaidZone: No MissionDefinitionResource assigned.")
		return

	ExtractionLoopManager.phase_changed.connect(_on_phase_changed)

	var gen := GridMapGenerator.new()
	var rooms : Array = gen.generate(mission_definition)

	if room_activity_system:
		room_activity_system.set_room_graph(rooms)

	if ai_director:
		ai_director.set_room_graph(rooms)
		ai_director.spawn_encounters()

	if minimap:
		minimap.set_room_graph(rooms)

	# Reveal the spawn room immediately
	if minimap and rooms.size() > 0:
		minimap.reveal_room(rooms[0].room_id)

	# Wire extraction zone
	if extraction_zone:
		if mission_definition.objective_type == MissionDefinitionResource.ObjectiveType.FIND_EXTRACTION:
			extraction_zone.starts_sealed = true

	CogitoGlobals.debug_log(true, "DemoRaidZone",
		"Demo raid zone ready — " + str(rooms.size()) + " rooms generated.")


func _on_phase_changed(phase : int) -> void:
	if phase == ExtractionLoopManager.Phase.DEBRIEF:
		# Return to hub after a short delay
		await get_tree().create_timer(1.5).timeout
		ExtractionLoopManager.close_debrief()

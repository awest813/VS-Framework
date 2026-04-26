## DemoHubScene controller.
##
## Demonstrates how to wire all VS Framework systems together in a hub scene.
## Extend or replace with your own hub logic.
extends Node3D
class_name DemoHubScene

@export var hub_ui : HubUI
@export var alife_simulator : ALifeSimulator
@export var days_between_raids : int = 3


func _ready() -> void:
	ExtractionLoopManager.phase_changed.connect(_on_phase_changed)
	ExtractionLoopManager.raid_started.connect(_on_raid_started)

	# Simulate world time passing since last raid
	if alife_simulator:
		alife_simulator.simulate_world(days_between_raids)


func _on_phase_changed(phase : int) -> void:
	if phase == ExtractionLoopManager.Phase.HUB:
		if hub_ui:
			hub_ui.show()
	else:
		if hub_ui:
			hub_ui.hide()


func _on_raid_started(session : RunSessionResource) -> void:
	# TODO: Replace with your mission scene path loading via CogitoSceneManager.
	CogitoGlobals.debug_log(true, "DemoHubScene",
		"Raid started for mission: " + session.mission_id + " — load your raid scene here.")

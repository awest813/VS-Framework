## RaidDeathScreen — shown when the player dies, displaying what was lost.
##
## Attach to a CanvasLayer or Control node. Connect to
## ExtractionLoopManager.raid_ended_death signal.
extends Control
class_name RaidDeathScreen

@export var label_title : Label
@export var label_subtitle : Label
@export var lost_items_container : VBoxContainer
@export var button_return_to_hub : Button


func _ready() -> void:
	hide()
	var loop : Node = get_node_or_null("/root/ExtractionLoopManager")
	if loop:
		loop.raid_ended_death.connect(_on_death)

	if button_return_to_hub:
		button_return_to_hub.pressed.connect(_on_return_pressed)


func _on_death(session : RunSessionResource) -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if label_title:
		label_title.text = "YOU DIED"

	if label_subtitle:
		label_subtitle.text = "All items carried into the raid are lost."

	if lost_items_container:
		for child in lost_items_container.get_children():
			child.queue_free()

		if session:
			for entry in session.stash_snapshot:
				var row := Label.new()
				row.text = "LOST: " + str(entry.get("item_name", "?")) + " x" + str(entry.get("quantity", 1))
				lost_items_container.add_child(row)


func _on_return_pressed() -> void:
	var loop : Node = get_node_or_null("/root/ExtractionLoopManager")
	if loop:
		loop.close_debrief()

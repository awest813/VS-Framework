@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("ExtractionLoopManager", "res://addons/vs_framework/ExtractionLoop/ExtractionLoopManager.gd")
	add_autoload_singleton("FactionRegistry", "res://addons/vs_framework/Factions/FactionRegistry.gd")
	add_autoload_singleton("QuestManager", "res://addons/vs_framework/Quests/QuestManager.gd")
	add_autoload_singleton("PlayerProgression", "res://addons/vs_framework/Progression/PlayerProgression.gd")
	print("VS Framework: Plugin enabled.")


func _exit_tree() -> void:
	remove_autoload_singleton("ExtractionLoopManager")
	remove_autoload_singleton("FactionRegistry")
	remove_autoload_singleton("QuestManager")
	remove_autoload_singleton("PlayerProgression")
	print("VS Framework: Plugin disabled.")

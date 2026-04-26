## ShelterNode — marks an area as safe from EmissionEvent radiation.
##
## Place an Area3D with this script under structural cover in the raid level.
## EmissionEvent queries all registered ShelterNodes each frame during an emission.
extends Area3D
class_name ShelterNode

var _player_inside : bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Returns true if the player is currently inside this shelter.
func is_player_sheltered() -> bool:
	return _player_inside


func _on_body_entered(body : Node3D) -> void:
	if body.is_in_group("Player"):
		_player_inside = true


func _on_body_exited(body : Node3D) -> void:
	if body.is_in_group("Player"):
		_player_inside = false

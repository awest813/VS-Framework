## EmissionEvent — a zone-wide danger that forces players to shelter.
##
## Place one EmissionEvent node in a raid scene.
## Wire shelter_nodes to an Array of ShelterNode area references.
## The event fires on a timer or can be triggered manually.
extends Node
class_name EmissionEvent

signal emission_warning(time_remaining : float)
signal emission_started
signal emission_ended

## Seconds of warning given before the emission arrives.
@export var warning_duration : float = 30.0

## Duration of the emission itself.
@export var emission_duration : float = 20.0

## Radiation per second applied to players outside shelter during emission.
@export var radiation_per_second : float = 5.0

## Schedule: time in seconds between automatic emissions (0 = manual only).
@export var auto_interval : float = 300.0

## All ShelterNode areas in the level. Populated at runtime or assigned in editor.
@export var shelter_nodes : Array[NodePath] = []

var _in_emission : bool = false
var _player_node : Node = null
var _shelter_node_refs : Array = []
var _warning_timer : Timer
var _emission_timer : Timer
var _auto_timer : Timer


func _ready() -> void:
	_warning_timer = _make_timer(warning_duration, _on_warning_timeout)
	_emission_timer = _make_timer(emission_duration, _on_emission_ended)

	if auto_interval > 0:
		_auto_timer = _make_timer(auto_interval, trigger_warning)
		_auto_timer.start()

	call_deferred("_cache_shelters")
	call_deferred("_find_player")


func _process(delta : float) -> void:
	if not _in_emission or not _player_node:
		return

	if not _is_in_shelter():
		var rad : RadiationAttribute = _player_node.find_child("RadiationAttribute", true, false) as RadiationAttribute
		if rad:
			rad.expose(radiation_per_second * delta)
		elif _player_node.has_method("decrease_attribute"):
			_player_node.decrease_attribute("health", radiation_per_second * delta)


## Starts the warning countdown. Call manually or it fires automatically.
func trigger_warning() -> void:
	if _in_emission:
		return
	CogitoGlobals.debug_log(true, "EmissionEvent", "WARNING — emission incoming in " + str(warning_duration) + "s")
	emission_warning.emit(warning_duration)
	_send_player_hint("⚠ EMISSION INCOMING — find shelter in " + str(int(warning_duration)) + "s!")
	_warning_timer.start()


func _on_warning_timeout() -> void:
	_in_emission = true
	emission_started.emit()
	_emission_timer.start()
	CogitoGlobals.debug_log(true, "EmissionEvent", "EMISSION started")


func _on_emission_ended() -> void:
	_in_emission = false
	emission_ended.emit()
	if _auto_interval_active():
		_auto_timer.start()
	CogitoGlobals.debug_log(true, "EmissionEvent", "Emission over")


func _is_in_shelter() -> bool:
	for shelter in _shelter_node_refs:
		if is_instance_valid(shelter) and shelter.is_player_sheltered():
			return true
	return false


func _cache_shelters() -> void:
	for path in shelter_nodes:
		var node := get_node_or_null(path)
		if node:
			_shelter_node_refs.append(node)


func _find_player() -> void:
	_player_node = get_tree().get_first_node_in_group("Player")


func _make_timer(duration : float, callback : Callable) -> Timer:
	var t := Timer.new()
	t.wait_time = duration
	t.one_shot = true
	t.timeout.connect(callback)
	add_child(t)
	return t


func _auto_interval_active() -> bool:
	return _auto_timer != null and auto_interval > 0


func _send_player_hint(message : String) -> void:
	if not _player_node:
		return
	var interaction_component = _player_node.get("player_interaction_component")
	if interaction_component and interaction_component.has_method("send_hint"):
		interaction_component.send_hint(null, message)

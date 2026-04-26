## FatigueAttribute — builds up over time. Stimulants suppress it; crash follows.
extends CogitoAttribute
class_name FatigueAttribute

## Fatigue accumulation per second during a raid.
@export var accumulation_rate : float = 0.3

## Movement speed penalty multiplier at maximum fatigue (0.5 = half speed).
@export var max_fatigue_speed_multiplier : float = 0.6

## Whether accumulation is currently active.
@export var is_accumulating : bool = true

## True when a stimulant is active (suppresses normal accumulation).
var is_suppressed : bool = false

## Crash accumulation multiplier applied after stimulant wears off.
@export var crash_multiplier : float = 3.0

## How many seconds the crash lasts after stimulant wears off.
@export var crash_duration : float = 15.0

var _crash_timer : Timer = null


func _ready() -> void:
	super._ready()
	_crash_timer = Timer.new()
	_crash_timer.wait_time = crash_duration
	_crash_timer.one_shot = true
	_crash_timer.timeout.connect(_on_crash_ended)
	add_child(_crash_timer)


func _process(delta : float) -> void:
	if not is_accumulating:
		return

	if is_suppressed:
		return

	add(accumulation_rate * delta)


## Returns a 0–1 multiplier that can be applied to movement speed.
func get_speed_multiplier() -> float:
	if value_max <= 0:
		return 1.0
	var ratio : float = value_current / value_max
	return lerp(1.0, max_fatigue_speed_multiplier, ratio)


## Apply a stimulant: suppresses fatigue for duration, then triggers a crash.
func apply_stimulant(suppress_duration : float) -> void:
	is_suppressed = true
	await get_tree().create_timer(suppress_duration).timeout
	_start_crash()


func _start_crash() -> void:
	is_suppressed = false
	# Temporarily multiply accumulation rate during the crash window.
	# Rate is restored inside _on_crash_ended; we capture it as a member so only one
	# callback path handles restoration.
	_pre_crash_rate = accumulation_rate
	accumulation_rate = _pre_crash_rate * crash_multiplier
	_crash_timer.start()

# Stored so _on_crash_ended can restore it without a closure.
var _pre_crash_rate : float = 0.0

func _on_crash_ended() -> void:
	accumulation_rate = _pre_crash_rate
	CogitoGlobals.debug_log(true, "FatigueAttribute", "Stimulant crash over")

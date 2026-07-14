class_name GameState
extends RefCounted

## Minimal authoritative runtime state for M01.
##
## This state owns only the non-negative simulation timeline in milliseconds.
## It deliberately does not own time-authority anchors, save schema data,
## inventory, Reapings, Halls, tutorial state, reports, or presentation state.
## Later simulation services advance the timeline through validated elapsed-time
## operations so tests, foreground play, forecasts, and offline reconciliation can
## share the same deterministic unit.

const ERR_NEGATIVE_ELAPSED := "GAME_STATE_NEGATIVE_ELAPSED"
const ERR_TIME_OVERFLOW := "GAME_STATE_TIME_OVERFLOW"
const INT64_MAX := FixedPoint.INT64_MAX

var simulation_time_msec: int = 0

func _init(initial_simulation_time_msec: int = 0) -> void:
	if initial_simulation_time_msec < 0:
		push_error("GameState requires a non-negative initial simulation_time_msec.")
		initial_simulation_time_msec = 0
	simulation_time_msec = initial_simulation_time_msec


func advance_simulation_time(elapsed_msec: int) -> Dictionary:
	if elapsed_msec < 0:
		return {"ok": false, "code": ERR_NEGATIVE_ELAPSED}
	if simulation_time_msec > INT64_MAX - elapsed_msec:
		return {"ok": false, "code": ERR_TIME_OVERFLOW}
	simulation_time_msec += elapsed_msec
	return {"ok": true, "code": "OK", "simulation_time_msec": simulation_time_msec}

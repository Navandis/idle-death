class_name SimulationRunService
extends RefCounted

## Scene-independent explicit-duration adapter for committed simulation runs and forecasts.
##
## This service owns only non-persisted run metadata: the caller-selected mode and,
## for forecasts, the detached projected GameState clone. It owns no gameplay
## formulas, no authoritative state, no clocks, no scene tree, no storage, no
## tutorial/progression presentation, and no report history. Every successful run
## delegates to SimulationEngine.resolve_elapsed() so foreground, offline-fixture,
## debug, and forecast callers use the same deterministic mutation path. Forecasts
## clone through GameState.deep_clone() before delegation; the caller receives that
## projected clone only on success, and the baseline state is never committed.

const OK := &""
const ERR_INVALID_MODE := &"SIM_RUN_INVALID_MODE"
const ERR_NEGATIVE_ELAPSED := SimulationEngine.ERR_NEGATIVE_ELAPSED
const ERR_STATE_INVALID := SimulationEngine.ERR_STATE_INVALID

const MODE_FOREGROUND_SUPPLIED := &"FOREGROUND_SUPPLIED"
const MODE_OFFLINE_FIXTURE := &"OFFLINE_FIXTURE"
const MODE_DEBUG := &"DEBUG"
const MODE_FORECAST := &"FORECAST"
const COMMITTED_MODES := [MODE_FOREGROUND_SUPPLIED, MODE_OFFLINE_FIXTURE, MODE_DEBUG]

var engine: SimulationEngine
var registry: ContentRegistry

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry
	engine = SimulationEngine.new(content_registry)

## Commits an explicit elapsed duration to `state` using one of the committed modes.
## The mode is diagnostic wrapper metadata only; it is not passed into the engine,
## stored in GameState, or allowed to select alternate formulas.
func run_committed(state: GameState, elapsed_msec: int, mode: StringName) -> SimulationRunResult:
	if not COMMITTED_MODES.has(mode):
		return SimulationRunResult.failure(mode, ERR_INVALID_MODE, elapsed_msec, "run_committed requires FOREGROUND_SUPPLIED, OFFLINE_FIXTURE, or DEBUG mode.")
	var validation := _validate_request(state, elapsed_msec)
	if not validation.ok:
		return SimulationRunResult.failure(mode, StringName(validation.code), elapsed_msec, validation.details)
	var engine_result := engine.resolve_elapsed(state, elapsed_msec)
	return SimulationRunResult.from_engine(mode, engine_result, null)

## Projects an explicit elapsed duration on a detached clone of the current state.
## Forecasts deliberately do not write saves, consume checkpoints, ingest reports,
## sample time, or replay hypothetical commands; M04E1 only answers "what happens
## if this exact current configuration runs for this supplied duration?".
func forecast(state: GameState, elapsed_msec: int) -> SimulationRunResult:
	var mode := MODE_FORECAST
	var validation := _validate_request(state, elapsed_msec)
	if not validation.ok:
		return SimulationRunResult.failure(mode, StringName(validation.code), elapsed_msec, validation.details)
	# Clone before resolving so every nested gameplay object in the projection is
	# caller-owned evidence rather than a mutable alias of the authoritative baseline.
	var projected := state.deep_clone()
	var engine_result := engine.resolve_elapsed(projected, elapsed_msec)
	if not engine_result.success:
		return SimulationRunResult.from_engine(mode, engine_result, null)
	return SimulationRunResult.from_engine(mode, engine_result, projected)

func _validate_request(state: GameState, elapsed_msec: int) -> Dictionary:
	if elapsed_msec < 0:
		return {"ok": false, "code": ERR_NEGATIVE_ELAPSED, "details": "Elapsed milliseconds must be non-negative."}
	var validation := GameStateValidator.validate(state, registry, true)
	if not validation.ok:
		return {"ok": false, "code": ERR_STATE_INVALID, "details": str(validation)}
	return {"ok": true}

class SimulationRunResult:
	extends RefCounted
	## Non-authoritative run wrapper. `engine_result` is the exact SimulationEngine
	## result; `projected_state` exists only for successful forecasts and is never
	## serialized by the persistence layer.
	var success: bool = false
	var mode: StringName = &""
	var error_code: StringName = &""
	var developer_details: String = ""
	var requested_elapsed_msec: int = 0
	var engine_result: SimulationEngine.SimulationResult = null
	var projected_state: GameState = null
	func _init(success_value := false, mode_value: StringName = &"", error_value: StringName = &"", details := "", requested := 0, engine_value: SimulationEngine.SimulationResult = null, projection: GameState = null) -> void:
		success = success_value
		mode = mode_value
		error_code = error_value
		developer_details = details
		requested_elapsed_msec = requested
		engine_result = engine_value
		projected_state = projection
	static func failure(mode: StringName, code: StringName, requested: int, details: String) -> SimulationRunResult:
		return SimulationRunResult.new(false, mode, code, details, requested, null, null)
	static func from_engine(mode: StringName, result: SimulationEngine.SimulationResult, projection: GameState) -> SimulationRunResult:
		return SimulationRunResult.new(result.success, mode, result.error_code, result.developer_details, result.requested_elapsed_msec, result, projection)

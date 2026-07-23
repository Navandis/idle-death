class_name M04CDebugAdvance
extends RefCounted

## Prototype-only adapter for developer time advancement in M04C.
##
## This wrapper owns no gameplay state, no clock, and no editor/UI behavior. It
## exists so debug tooling can delegate explicit elapsed milliseconds to the same
## SimulationEngine used by tests, preserving the one-engine rule while later
## application-shell wiring remains deferred.

var run_service: SimulationRunService

func _init(content_registry: ContentRegistry) -> void:
	run_service = SimulationRunService.new(content_registry)

## Advances the supplied state by an explicit millisecond amount through the shared run service.
func advance_msec(state: GameState, elapsed_msec: int) -> SimulationResult:
	var run_result := run_service.run_committed(state, elapsed_msec, SimulationRunService.MODE_DEBUG)
	if run_result.simulation_result != null:
		return run_result.simulation_result
	return SimulationResult.failure(run_result.error_code, elapsed_msec, run_result.developer_details)

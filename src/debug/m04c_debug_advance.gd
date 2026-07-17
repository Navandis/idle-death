class_name M04CDebugAdvance
extends RefCounted

## Prototype-only adapter for developer time advancement in M04C.
##
## This wrapper owns no gameplay state, no clock, and no editor/UI behavior. It
## exists so debug tooling can delegate explicit elapsed milliseconds to the same
## SimulationEngine used by tests, preserving the one-engine rule while later
## application-shell wiring remains deferred.

var engine: SimulationEngine

func _init(content_registry: ContentRegistry) -> void:
	engine = SimulationEngine.new(content_registry)

## Advances the supplied state by an explicit millisecond amount through M04C rules.
func advance_msec(state: GameState, elapsed_msec: int) -> SimulationEngine.SimulationResult:
	return engine.resolve_elapsed(state, elapsed_msec)

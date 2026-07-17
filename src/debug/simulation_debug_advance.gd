class_name SimulationDebugAdvance
extends RefCounted

## Minimal developer adapter for M04C explicit time advancement.
##
## This helper owns no gameplay rules and reads no clocks. Debug tools can pass a
## chosen millisecond duration here and receive the exact same SimulationEngine
## result as tests, forecasts, or future application wiring.

var engine: SimulationEngine

func _init(simulation_engine: SimulationEngine) -> void:
	engine = simulation_engine

func advance_by_msec(state: GameState, elapsed_msec: int) -> SimulationEngine.SimulationResult:
	return engine.resolve_elapsed_msec(state, elapsed_msec)

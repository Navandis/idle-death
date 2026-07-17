class_name CoreReapingFlowContract
extends RefCounted

## Shared M04C core-flow key and source-ownership contract.
##
## This small domain contract lets GameStateValidator, SimulationEngine, tests,
## and trace tools agree on durable residual-key names without making validators
## depend on the full simulation engine. It owns no simulation formulas, clocks,
## content records, persistence bytes, UI, reports, forecasts, or platform data.

const FLOW_CORE_RETURNS_PROGRESS_SUBUNITS := &"FLOW_CORE_RETURNS_PROGRESS_SUBUNITS"
const FLOW_CORE_RETURNS_RATE_CARRY_UNITS := &"FLOW_CORE_RETURNS_RATE_CARRY_UNITS"
const FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS := &"FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS"
const FLOW_CORE_ESSENCE_RATE_CARRY_UNITS := &"FLOW_CORE_ESSENCE_RATE_CARRY_UNITS"
const FLOW_CORE_MASTERY_RATE_CARRY_UNITS := &"FLOW_CORE_MASTERY_RATE_CARRY_UNITS"

const CORE_FLOW_KEYS := [
	FLOW_CORE_RETURNS_PROGRESS_SUBUNITS,
	FLOW_CORE_RETURNS_RATE_CARRY_UNITS,
	FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS,
	FLOW_CORE_ESSENCE_RATE_CARRY_UNITS,
	FLOW_CORE_MASTERY_RATE_CARRY_UNITS,
]

const PROHIBITED_SOURCE_TOKENS := [
	"Time.get_",
	"Time.",
	"get_ticks",
	"Date",
	"FileAccess",
	"DirAccess",
	"Steam",
	"GodotSteam",
	"SceneTree",
	"Node",
	"_process",
	"_physics_process",
	"report",
	"forecast",
	"M04D",
]

static func is_known_core_key(key: Variant) -> bool:
	return CORE_FLOW_KEYS.has(StringName(key))

static func required_trace_markers() -> Array[String]:
	return [
		"TRACE M04C overdue_60s_returns=69_essence=6_mastery=1000000_cycles=1",
		"TRACE M04C one_shot_equals_chunks=PASS",
		"TRACE M04C settlement_boundary_msec=870",
		"TRACE M04C settlement_end_returns=3_backlog=0_lifecycle=SETTLED",
		"TRACE M04C settlement_event_once=PASS",
		"TRACE M04C settled_mastery_and_cycle_continue=PASS",
		"TRACE M04C core_residuals_return=625375_essence=315250_mastery_carry=40000",
		"TRACE M04C inactive_produces_nothing=PASS",
		"TRACE M04C idle_timeline_advances=PASS",
		"TRACE M04C save_round_trip=PASS",
		"TRACE M04C no_clock_sources=PASS",
	]

class_name SimulationEvent
extends RefCounted

## Common envelope for the closed public simulation-event union.  The base type
## deliberately contains no payload dictionary and is not a valid public event
## instance by itself; only the two concrete subclasses are accepted by the
## projector's structural validation.  Events are detached observations, never
## mutation commands or persisted state.  Times are simulation milliseconds.

const EVENT_THRESHOLD_SETTLED := &"THRESHOLD_SETTLED"
const EVENT_OUTPUT_CHANNEL_BANKED := &"OUTPUT_CHANNEL_BANKED"
const EVENT_PRIORITY_CHANNEL_GAIN := 100
const EVENT_PRIORITY_LIFECYCLE := 200
const SIMULATION_ENGINE_SOURCE := &"SIMULATION_ENGINE"

var event_type: StringName:
	get: return _event_type
var occurred_simulation_msec: int:
	get: return _occurred_simulation_msec
var priority: int:
	get: return _priority
var segment_index: int:
	get: return _segment_index
var subject_id: StringName:
	get: return _subject_id
var source_id: StringName:
	get: return _source_id
var reportable: bool:
	get: return _reportable
var tutorial_relevant: bool:
	get: return _tutorial_relevant

var _event_type: StringName
var _occurred_simulation_msec: int
var _priority: int
var _segment_index: int
var _subject_id: StringName
var _source_id: StringName
var _reportable: bool
var _tutorial_relevant: bool

func _init(
	type_value: StringName,
	occurred_value: int,
	priority_value: int,
	segment_index_value: int,
	subject_value: StringName,
	source_value: StringName,
	reportable_value: bool = true,
	tutorial_relevant_value: bool = true
) -> void:
	_event_type = type_value
	_occurred_simulation_msec = occurred_value
	_priority = priority_value
	_segment_index = segment_index_value
	_subject_id = subject_value
	_source_id = source_value
	_reportable = reportable_value
	_tutorial_relevant = tutorial_relevant_value

## Base copies are useful for diagnostics but remain rejected by closed-union validation.
func detached_copy() -> SimulationEvent:
	return SimulationEvent.new(_event_type, _occurred_simulation_msec, _priority, _segment_index, _subject_id, _source_id, _reportable, _tutorial_relevant)

## Compares the common envelope fields without relying on RefCounted identity.
func value_equals(other: SimulationEvent) -> bool:
	return other != null \
		and _event_type == other.event_type \
		and _occurred_simulation_msec == other.occurred_simulation_msec \
		and _priority == other.priority \
		and _segment_index == other.segment_index \
		and _subject_id == other.subject_id \
		and _source_id == other.source_id \
		and _reportable == other.reportable \
		and _tutorial_relevant == other.tutorial_relevant

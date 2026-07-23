class_name SimulationResult
extends RefCounted

## Detached public envelope for one explicit simulation request.  It owns only
## typed explanatory facts and timing metadata; it never owns or authorizes a
## GameState, candidate, transaction, report, clock, or persistence record.
## Successful times are simulation milliseconds and all child facts are copied
## by value so a retained forecast or report input cannot alias a later run.

const KIND_FAILURE := &"FAILURE"
const KIND_ZERO_DURATION := &"ZERO_DURATION"
const KIND_TIMELINE_ONLY := &"TIMELINE_ONLY"
const KIND_ACTIVE_REAPING := &"ACTIVE_REAPING"

var result_kind: StringName:
	get: return _result_kind
var success: bool:
	get: return _success
var error_code: StringName:
	get: return _error_code
var developer_details: String:
	get: return _developer_details
var requested_elapsed_msec: int:
	get: return _requested_elapsed_msec
var committed_elapsed_msec: int:
	get: return _committed_elapsed_msec
var baseline_simulation_time_msec: int:
	get: return _baseline_simulation_time_msec
var result_simulation_time_msec: int:
	get: return _result_simulation_time_msec
var content_revision: String:
	get: return _content_revision
var segments: Array[SimulationSegmentResult]:
	get:
		var detached: Array[SimulationSegmentResult] = []
		for segment in _segments:
			detached.append(segment.detached_copy())
		return detached
var events: Array[SimulationEvent]:
	get:
		var detached: Array[SimulationEvent] = []
		for event in _events:
			detached.append(event.detached_copy())
		return detached

var _result_kind: StringName
var _success: bool
var _error_code: StringName
var _developer_details: String
var _requested_elapsed_msec: int
var _committed_elapsed_msec: int
var _baseline_simulation_time_msec: int
var _result_simulation_time_msec: int
var _content_revision: String
var _segments: Array[SimulationSegmentResult] = []
var _events: Array[SimulationEvent] = []

func _init(
	kind_value: StringName,
	success_value: bool,
	error_value: StringName,
	details_value: String,
	requested_value: int,
	committed_value: int,
	baseline_value: int,
	result_time_value: int,
	content_value: String,
	segment_values: Array[SimulationSegmentResult] = [],
	event_values: Array[SimulationEvent] = []
) -> void:
	_result_kind = kind_value
	_success = success_value
	_error_code = error_value
	_developer_details = details_value
	_requested_elapsed_msec = requested_value
	_committed_elapsed_msec = committed_value
	_baseline_simulation_time_msec = baseline_value
	_result_simulation_time_msec = result_time_value
	_content_revision = content_value
	for segment in segment_values:
		_segments.append(segment.detached_copy())
	for event in event_values:
		_events.append(event.detached_copy())

static func failure(code: StringName, requested: int, details: String, cursor: int = 0) -> SimulationResult:
	return SimulationResult.new(KIND_FAILURE, false, code, details, requested, 0, cursor, cursor, "")

static func zero_duration(cursor: int = 0) -> SimulationResult:
	return SimulationResult.new(KIND_ZERO_DURATION, true, &"", "", 0, 0, cursor, cursor, "")

static func timeline_only(requested: int, baseline: int, result_time: int, content: String) -> SimulationResult:
	return SimulationResult.new(KIND_TIMELINE_ONLY, true, &"", "", requested, requested, baseline, result_time, content)

static func active_reaping(requested: int, baseline: int, result_time: int, content: String, segment_values: Array[SimulationSegmentResult], event_values: Array[SimulationEvent]) -> SimulationResult:
	return SimulationResult.new(KIND_ACTIVE_REAPING, true, &"", "", requested, requested, baseline, result_time, content, segment_values, event_values)

## Returns a deeply detached envelope and all typed child facts.
func detached_copy() -> SimulationResult:
	return SimulationResult.new(
		_result_kind,
		_success,
		_error_code,
		_developer_details,
		_requested_elapsed_msec,
		_committed_elapsed_msec,
		_baseline_simulation_time_msec,
		_result_simulation_time_msec,
		_content_revision,
		_segments,
		_events
	)

## Compares the complete public value without comparing RefCounted identity.
func value_equals(other: SimulationResult) -> bool:
	if other == null or _result_kind != other.result_kind or _success != other.success \
		or _error_code != other.error_code or _developer_details != other.developer_details \
		or _requested_elapsed_msec != other.requested_elapsed_msec or _committed_elapsed_msec != other.committed_elapsed_msec \
		or _baseline_simulation_time_msec != other.baseline_simulation_time_msec \
		or _result_simulation_time_msec != other.result_simulation_time_msec or _content_revision != other.content_revision:
		return false
	var other_segments := other.segments
	var other_events := other.events
	if _segments.size() != other_segments.size() or _events.size() != other_events.size(): return false
	for index in range(_segments.size()):
		if not _segments[index].value_equals(other_segments[index]): return false
	for index in range(_events.size()):
		if not _events[index].value_equals(other_events[index]): return false
	return true

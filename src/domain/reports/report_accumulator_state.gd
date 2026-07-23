class_name ReportAccumulatorState
extends RefCounted

## Mutable live report accumulator owned by `ReportState`.
##
## It stores explanatory facts only and never grants or removes gameplay
## resources. Endpoints are simulation milliseconds. Child maps and arrays are
## explicitly cloned; no ingestion, compaction, clearing, or snapshot behavior
## is implemented in this slice.

var window_started_simulation_msec: int = 0
var window_ended_simulation_msec: int = 0
var ingested_run_count: int = 0
var committed_mode_counts: Dictionary = {}
var attribution_slices: Dictionary = {}
var event_type_counts: Dictionary = {}
var recent_events: Array[ReportEventRecord] = []
var omitted_event_count: int = 0

func _init(cursor_msec: int = 0) -> void:
	window_started_simulation_msec = cursor_msec
	window_ended_simulation_msec = cursor_msec

func deep_clone() -> ReportAccumulatorState:
	var clone := ReportAccumulatorState.new(window_ended_simulation_msec)
	clone.window_started_simulation_msec = window_started_simulation_msec
	clone.ingested_run_count = ingested_run_count
	clone.omitted_event_count = omitted_event_count
	for mode in committed_mode_counts.keys(): clone.committed_mode_counts[mode] = committed_mode_counts[mode]
	for key in attribution_slices.keys(): clone.attribution_slices[key] = attribution_slices[key].deep_clone()
	for event_type_key in event_type_counts.keys(): clone.event_type_counts[event_type_key] = event_type_counts[event_type_key]
	for event in recent_events: clone.recent_events.append(event.deep_clone())
	return clone

func value_equals(other: ReportAccumulatorState) -> bool:
	if other == null or window_started_simulation_msec != other.window_started_simulation_msec or window_ended_simulation_msec != other.window_ended_simulation_msec or ingested_run_count != other.ingested_run_count or omitted_event_count != other.omitted_event_count or committed_mode_counts != other.committed_mode_counts or event_type_counts != other.event_type_counts: return false
	if attribution_slices.size() != other.attribution_slices.size() or recent_events.size() != other.recent_events.size(): return false
	for key in attribution_slices.keys():
		if not other.attribution_slices.has(key) or not attribution_slices[key].value_equals(other.attribution_slices[key]): return false
	for index in range(recent_events.size()):
		if not recent_events[index].value_equals(other.recent_events[index]): return false
	return true

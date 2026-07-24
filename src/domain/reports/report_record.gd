class_name ReportRecord
extends RefCounted

## Detached immutable archive record for one report window.
##
## The record owns a private deep copy of its accumulator and exposes another
## copy on read. It has no report commands, read-model behavior, file access,
## clocks, or gameplay authority. Snapshot times are simulation milliseconds.

var _report_sequence: int
var _snapshot_reason: StringName
var _snapshot_simulation_msec: int
var _window: ReportAccumulatorState

var report_sequence: int:
	get:
		return _report_sequence

var snapshot_reason: StringName:
	get:
		return _snapshot_reason

var snapshot_simulation_msec: int:
	get:
		return _snapshot_simulation_msec

var window: ReportAccumulatorState:
	get:
		return _window.deep_clone()

func _window_for_validation() -> Variant:
	## Borrow the private child only for structural validation.
	##
	## The normal `window` getter deliberately returns a detached clone. A
	## validator must first prove that the private child is a valid accumulator;
	## otherwise calling that getter on malformed state would execute
	## `deep_clone()` on null or a wrong-class data and raise a script error.
	return _window

func _init(sequence_value: int = 0, reason_value: StringName = &"", snapshot_value: int = 0, window_value: ReportAccumulatorState = null) -> void:
	_report_sequence = sequence_value
	_snapshot_reason = reason_value
	_snapshot_simulation_msec = snapshot_value
	_window = window_value.deep_clone() if window_value != null else ReportAccumulatorState.new(snapshot_value)

func deep_clone() -> ReportRecord:
	return ReportRecord.new(report_sequence, snapshot_reason, snapshot_simulation_msec, _window)

func value_equals(other: ReportRecord) -> bool:
	return other != null and report_sequence == other.report_sequence and snapshot_reason == other.snapshot_reason and snapshot_simulation_msec == other.snapshot_simulation_msec and _window.value_equals(other._window)

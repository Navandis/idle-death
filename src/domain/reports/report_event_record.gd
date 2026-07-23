class_name ReportEventRecord
extends RefCounted

## Immutable compact detail for one reportable simulation event.
##
## Only the common typed event fields persist. Raw event payloads, segment
## objects, and simulation result references are deliberately excluded. The
## event time is a simulation millisecond and is validated against its window.

var event_sequence: int
var event_type: StringName
var occurred_simulation_msec: int
var priority: int
var subject_id: StringName
var source_id: StringName

func _init(sequence_value: int = 0, type_value: StringName = &"", occurred_value: int = 0, priority_value: int = 0, subject_value: StringName = &"", source_value: StringName = &"") -> void:
	event_sequence = sequence_value
	event_type = type_value
	occurred_simulation_msec = occurred_value
	priority = priority_value
	subject_id = subject_value
	source_id = source_value

func deep_clone() -> ReportEventRecord:
	return ReportEventRecord.new(event_sequence, event_type, occurred_simulation_msec, priority, subject_id, source_id)

func value_equals(other: ReportEventRecord) -> bool:
	return other != null and event_sequence == other.event_sequence and event_type == other.event_type and occurred_simulation_msec == other.occurred_simulation_msec and priority == other.priority and subject_id == other.subject_id and source_id == other.source_id

class_name ReportState
extends RefCounted

## Save-owned report accumulator for already-applied simulation output.
##
## ReportState owns only explanatory slices, bounded event details, and bounded
## recent archive records. It does not own gameplay inventory, production rules,
## clocks, UI state, save files, or Codex analytics. All cursors and interval
## endpoints are simulation milliseconds; all quantities are already-applied
## authoritative deltas copied from SimulationEngine results.

const MAX_EVENT_DETAILS := 64
const MAX_HISTORY_RECORDS := 20
const REASON_MANUAL_REVIEW := &"MANUAL_REVIEW"
const REASON_OFFLINE_RETURN := &"OFFLINE_RETURN"
const REASON_SYSTEM_BOUNDARY := &"SYSTEM_BOUNDARY"
const MODE_FOREGROUND_SUPPLIED := &"FOREGROUND_SUPPLIED"
const MODE_OFFLINE_FIXTURE := &"OFFLINE_FIXTURE"
const MODE_DEBUG := &"DEBUG"
const VALID_REASONS := [REASON_MANUAL_REVIEW, REASON_OFFLINE_RETURN, REASON_SYSTEM_BOUNDARY]
const VALID_MODES := [MODE_FOREGROUND_SUPPLIED, MODE_OFFLINE_FIXTURE, MODE_DEBUG]

var report_cursor_msec: int = 0
var next_report_sequence: int = 1
var next_event_sequence: int = 1
var dropped_history_record_count: int = 0
var live: ReportWindow = ReportWindow.new()
var history: Array[ReportRecord] = []

func _init(cursor_msec := 0) -> void:
	report_cursor_msec = cursor_msec
	live.start_simulation_msec = cursor_msec
	live.end_simulation_msec = cursor_msec

func deep_clone() -> ReportState:
	var clone := ReportState.new(report_cursor_msec)
	clone.next_report_sequence = next_report_sequence
	clone.next_event_sequence = next_event_sequence
	clone.dropped_history_record_count = dropped_history_record_count
	clone.live = live.deep_clone()
	clone.history.clear()
	for record in history:
		clone.history.append(record.deep_clone())
	return clone

func reset_live_at_cursor() -> void:
	live = ReportWindow.new()
	live.start_simulation_msec = report_cursor_msec
	live.end_simulation_msec = report_cursor_msec

class ReportWindow:
	extends RefCounted
	## Mutable live report window or immutable archived payload after deep copy.
	var start_simulation_msec: int = 0
	var end_simulation_msec: int = 0
	var run_count: int = 0
	var mode_counts: Dictionary = {}
	var slices: Dictionary = {}
	var events_by_type: Dictionary = {}
	var event_details: Array[ReportEventDetail] = []
	var omitted_oldest_event_detail_count: int = 0
	func deep_clone() -> ReportWindow:
		var clone := ReportWindow.new()
		clone.start_simulation_msec = start_simulation_msec; clone.end_simulation_msec = end_simulation_msec; clone.run_count = run_count
		clone.mode_counts = mode_counts.duplicate(true); clone.events_by_type = events_by_type.duplicate(true)
		for key in slices.keys(): clone.slices[key] = slices[key].deep_clone()
		for detail in event_details: clone.event_details.append(detail.deep_clone())
		clone.omitted_oldest_event_detail_count = omitted_oldest_event_detail_count
		return clone
	func is_empty() -> bool:
		return run_count == 0 and slices.is_empty() and event_details.is_empty() and omitted_oldest_event_detail_count == 0

class AttributionSlice:
	extends RefCounted
	## Canonical aggregation key: Threshold, assignment revision, and lifecycle.
	var threshold_id: StringName = &""
	var assignment_revision: int = 0
	var lifecycle_state: StringName = &""
	var form_id: StringName = &""
	var writ_id: StringName = &""
	var retinue_ids: Array[StringName] = []
	var start_simulation_msec: int = 0
	var end_simulation_msec: int = 0
	var elapsed_msec: int = 0
	var returned_souls_delta: int = 0
	var backlog_delta: int = 0
	var completed_cycles_delta: int = 0
	var inventory_gains: Dictionary = {}
	var mastery_gains: Dictionary = {}
	var channel_summaries: Dictionary = {}
	func deep_clone() -> AttributionSlice:
		var clone := AttributionSlice.new()
		clone.threshold_id = threshold_id; clone.assignment_revision = assignment_revision; clone.lifecycle_state = lifecycle_state
		clone.form_id = form_id; clone.writ_id = writ_id; clone.retinue_ids = retinue_ids.duplicate()
		clone.start_simulation_msec = start_simulation_msec; clone.end_simulation_msec = end_simulation_msec; clone.elapsed_msec = elapsed_msec
		clone.returned_souls_delta = returned_souls_delta; clone.backlog_delta = backlog_delta; clone.completed_cycles_delta = completed_cycles_delta
		clone.inventory_gains = inventory_gains.duplicate(true); clone.mastery_gains = mastery_gains.duplicate(true)
		for key in channel_summaries.keys(): clone.channel_summaries[key] = channel_summaries[key].deep_clone()
		return clone
	func loadout_key() -> String:
		var retinues := []
		for id in retinue_ids: retinues.append(str(id))
		return "%s|%s|%s" % [form_id, writ_id, ",".join(retinues)]

class ChannelSummary:
	extends RefCounted
	var channel_id: StringName = &""
	var output_item_id: StringName = &""
	var banked_units_delta: int = 0
	var first_progress_subunits_before: int = 0
	var latest_progress_subunits_after: int = 0
	var first_rate_carry_units_before: int = 0
	var latest_rate_carry_units_after: int = 0
	var first_total_banked_units_before: int = 0
	var latest_total_banked_units_after: int = 0
	func deep_clone() -> ChannelSummary:
		var clone := ChannelSummary.new()
		clone.channel_id = channel_id; clone.output_item_id = output_item_id; clone.banked_units_delta = banked_units_delta
		clone.first_progress_subunits_before = first_progress_subunits_before; clone.latest_progress_subunits_after = latest_progress_subunits_after
		clone.first_rate_carry_units_before = first_rate_carry_units_before; clone.latest_rate_carry_units_after = latest_rate_carry_units_after
		clone.first_total_banked_units_before = first_total_banked_units_before; clone.latest_total_banked_units_after = latest_total_banked_units_after
		return clone

class ReportEventDetail:
	extends RefCounted
	var event_sequence: int = 0
	var event_type: StringName = &""
	var occurred_simulation_msec: int = 0
	var priority: int = 0
	var subject_id: StringName = &""
	var source_id: StringName = &""
	func deep_clone() -> ReportEventDetail:
		var clone := ReportEventDetail.new()
		clone.event_sequence = event_sequence; clone.event_type = event_type; clone.occurred_simulation_msec = occurred_simulation_msec
		clone.priority = priority; clone.subject_id = subject_id; clone.source_id = source_id
		return clone

class ReportRecord:
	extends RefCounted
	var report_sequence: int = 0
	var snapshot_reason: StringName = &""
	var snapshot_simulation_msec: int = 0
	var window: ReportWindow = ReportWindow.new()
	func deep_clone() -> ReportRecord:
		var clone := ReportRecord.new()
		clone.report_sequence = report_sequence; clone.snapshot_reason = snapshot_reason; clone.snapshot_simulation_msec = snapshot_simulation_msec; clone.window = window.deep_clone()
		return clone

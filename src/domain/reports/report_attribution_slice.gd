class_name ReportAttributionSlice
extends RefCounted

## Mutable aggregate facts for one Threshold, assignment revision, and
## lifecycle episode. It owns detached loadout, gain maps, and channel facts;
## it does not own inventory or mutate gameplay. All times are simulation
## milliseconds and all quantities are checked non-negative integer domains.

var threshold_id: StringName
var assignment_revision: int
var lifecycle_state: StringName
var loadout_identity: ReportLoadoutIdentity
var window_started_simulation_msec: int
var window_ended_simulation_msec: int
var elapsed_msec: int
var returned_souls_delta: int
var backlog_reduced: int
var completed_cycles_delta: int
var inventory_gains_by_item_id: Dictionary = {}
var mastery_gains_subunits_by_form_id: Dictionary = {}
var channel_summaries_by_channel_id: Dictionary = {}

func _init(
	threshold_value: StringName = &"",
	revision_value: int = 0,
	lifecycle_value: StringName = &"",
	loadout_value: ReportLoadoutIdentity = null,
	window_start_value: int = 0,
	window_end_value: int = 0,
	elapsed_value: int = 0,
	returned_value: int = 0,
	backlog_value: int = 0,
	cycles_value: int = 0
) -> void:
	threshold_id = threshold_value
	assignment_revision = revision_value
	lifecycle_state = lifecycle_value
	loadout_identity = loadout_value.deep_clone() if loadout_value != null else ReportLoadoutIdentity.new()
	window_started_simulation_msec = window_start_value
	window_ended_simulation_msec = window_end_value
	elapsed_msec = elapsed_value
	returned_souls_delta = returned_value
	backlog_reduced = backlog_value
	completed_cycles_delta = cycles_value

func deep_clone() -> ReportAttributionSlice:
	var clone := ReportAttributionSlice.new(threshold_id, assignment_revision, lifecycle_state, loadout_identity, window_started_simulation_msec, window_ended_simulation_msec, elapsed_msec, returned_souls_delta, backlog_reduced, completed_cycles_delta)
	for item_id in inventory_gains_by_item_id.keys(): clone.inventory_gains_by_item_id[item_id] = inventory_gains_by_item_id[item_id]
	for form_id in mastery_gains_subunits_by_form_id.keys(): clone.mastery_gains_subunits_by_form_id[form_id] = mastery_gains_subunits_by_form_id[form_id]
	for channel_id in channel_summaries_by_channel_id.keys(): clone.channel_summaries_by_channel_id[channel_id] = channel_summaries_by_channel_id[channel_id].deep_clone()
	return clone

func canonical_identity_key() -> String:
	return "%s|%s|%s" % [str(threshold_id), str(assignment_revision), str(lifecycle_state)]

func value_equals(other: ReportAttributionSlice) -> bool:
	if other == null or threshold_id != other.threshold_id or assignment_revision != other.assignment_revision or lifecycle_state != other.lifecycle_state or not loadout_identity.value_equals(other.loadout_identity): return false
	if window_started_simulation_msec != other.window_started_simulation_msec or window_ended_simulation_msec != other.window_ended_simulation_msec or elapsed_msec != other.elapsed_msec or returned_souls_delta != other.returned_souls_delta or backlog_reduced != other.backlog_reduced or completed_cycles_delta != other.completed_cycles_delta: return false
	if inventory_gains_by_item_id != other.inventory_gains_by_item_id or mastery_gains_subunits_by_form_id != other.mastery_gains_subunits_by_form_id: return false
	if channel_summaries_by_channel_id.size() != other.channel_summaries_by_channel_id.size(): return false
	for channel_id in channel_summaries_by_channel_id.keys():
		if not other.channel_summaries_by_channel_id.has(channel_id) or not channel_summaries_by_channel_id[channel_id].value_equals(other.channel_summaries_by_channel_id[channel_id]): return false
	return true

class_name GameState
extends RefCounted

## Authoritative gameplay-state aggregate for the M04A persistence foundation.
##
## This object owns mutable runtime gameplay facts that must survive save/load:
## the monotonic simulation timeline plus the first bounded families needed by
## later Reaping slices (inventory, Forms, Thresholds, Reaping records, and
## command-tether progression).  It does not own content definitions, byte/JSON
## save primitives, clocks, trusted-time anchors, UI, dispatch commands, elapsed
## production, forecasts, reports, Halls, tutorial state, or Steam/platform data.
## All time values stored here are simulation milliseconds and all fractional
## gameplay values use FixedPoint.SCALE subunits.  Clone and mapping are explicit
## so forecast and migration candidates can be mutated without leaking into live
## state.

const ERR_NEGATIVE_ELAPSED := "GAME_STATE_NEGATIVE_ELAPSED"
const ERR_TIME_OVERFLOW := "GAME_STATE_TIME_OVERFLOW"
const INT64_MAX := FixedPoint.INT64_MAX

var simulation_time_msec: int = 0
var inventory: InventoryState = InventoryState.new()
var forms: Dictionary = {}
var thresholds: Dictionary = {}
var reapings: Dictionary = {}
var progression: ProgressionState = ProgressionState.new()
var report_state: ReportState = ReportState.new()

func _init(initial_simulation_time_msec: int = 0) -> void:
	if initial_simulation_time_msec < 0:
		push_error("GameState requires a non-negative initial simulation_time_msec.")
		initial_simulation_time_msec = 0
	simulation_time_msec = initial_simulation_time_msec
	report_state = ReportState.new(initial_simulation_time_msec)

func advance_simulation_time(elapsed_msec: int) -> Dictionary:
	if elapsed_msec < 0:
		return {"ok": false, "code": ERR_NEGATIVE_ELAPSED}
	if simulation_time_msec > INT64_MAX - elapsed_msec:
		return {"ok": false, "code": ERR_TIME_OVERFLOW}
	simulation_time_msec += elapsed_msec
	return {"ok": true, "code": "OK", "simulation_time_msec": simulation_time_msec}


func copy_from(other: GameState) -> void:
	## Replaces this aggregate with a fully validated candidate at transaction commit.
	## Callers must validate `other` first; this method intentionally performs no
	## gameplay logic, clock reads, or partial field derivation.
	simulation_time_msec = other.simulation_time_msec
	inventory = other.inventory.deep_clone()
	forms.clear()
	for key in other.forms.keys(): forms[key] = other.forms[key].deep_clone()
	thresholds.clear()
	for key in other.thresholds.keys(): thresholds[key] = other.thresholds[key].deep_clone()
	reapings.clear()
	for key in other.reapings.keys(): reapings[key] = other.reapings[key].deep_clone()
	progression = other.progression.deep_clone()
	report_state = other.report_state.deep_clone()

func deep_clone() -> GameState:
	var clone := GameState.new(simulation_time_msec)
	clone.inventory = inventory.deep_clone()
	clone.progression = progression.deep_clone()
	clone.report_state = report_state.deep_clone()
	for key in forms.keys():
		clone.forms[key] = forms[key].deep_clone()
	for key in thresholds.keys():
		clone.thresholds[key] = thresholds[key].deep_clone()
	for key in reapings.keys():
		clone.reapings[key] = reapings[key].deep_clone()
	return clone

class InventoryState:
	extends RefCounted
	## Owns whole-count item inventory entries; reservations are ledgers only.
	var entries: Dictionary = {}
	func deep_clone() -> InventoryState:
		var clone := InventoryState.new()
		for key in entries.keys(): clone.entries[key] = entries[key].deep_clone()
		return clone

class InventoryEntryState:
	extends RefCounted
	## Whole inventory total plus non-consuming reservation amounts by stable key.
	var total: int = 0
	var reservations: Dictionary = {}
	func _init(total_value: int = 0, reservations_value: Dictionary = {}) -> void:
		total = total_value; reservations = reservations_value.duplicate(true)
	func deep_clone() -> InventoryEntryState:
		return InventoryEntryState.new(total, reservations)

class FormState:
	extends RefCounted
	## Stores Form visibility/awakening and use-based Mastery; no awakening command.
	var revealed: bool = false
	var awakened: bool = false
	var mastery_subunits: int = 0
	var awakened_by: StringName = &""
	func _init(revealed_value := false, awakened_value := false, mastery_value := 0, source: StringName = &"") -> void:
		revealed = revealed_value; awakened = awakened_value; mastery_subunits = mastery_value; awakened_by = source
	func deep_clone() -> FormState:
		return FormState.new(revealed, awakened, mastery_subunits, awakened_by)

class ThresholdState:
	extends RefCounted
	## Stores Threshold knowledge/lifecycle totals and durable channel acquisition work.
	var knowledge_state: StringName = &"UNKNOWN"
	var availability_state: StringName = &"LOCKED"
	var lifecycle_state: StringName = &"OVERDUE"
	var remaining_backlog: int = 0
	var persistent_returns_total: int = 0
	var familiarity_subunits: int = 0
	var channel_acquisition: Dictionary = {}
	func deep_clone() -> ThresholdState:
		var clone := ThresholdState.new()
		clone.knowledge_state = knowledge_state; clone.availability_state = availability_state; clone.lifecycle_state = lifecycle_state
		clone.remaining_backlog = remaining_backlog; clone.persistent_returns_total = persistent_returns_total; clone.familiarity_subunits = familiarity_subunits
		for key in channel_acquisition.keys(): clone.channel_acquisition[key] = channel_acquisition[key].deep_clone()
		return clone

class ThresholdAcquisitionState:
	extends RefCounted
	## Normalized work toward the next whole channel output; M04A never advances it.
	var progress_subunits: int = 0
	var rate_carry_units: int = 0
	var total_banked_units: int = 0
	func _init(progress := 0, carry := 0, banked := 0) -> void:
		progress_subunits = progress; rate_carry_units = carry; total_banked_units = banked
	func deep_clone() -> ThresholdAcquisitionState:
		return ThresholdAcquisitionState.new(progress_subunits, rate_carry_units, total_banked_units)

class ReapingState:
	extends RefCounted
	## Structural persistent-Reaping assignment record; no dispatch or production logic.
	var threshold_id: StringName = &""
	var is_active: bool = false
	var form_id: StringName = &""
	var writ_id: StringName = &""
	var retinue_ids: Array[StringName] = []
	var assignment_revision: int = 0
	var cycle_phase_msec: int = 0
	var completed_cycle_count: int = 0
	var flow_carry_units: Dictionary = {}
	var started_simulation_msec: int = 0
	var last_configuration_change_simulation_msec: int = 0
	func deep_clone() -> ReapingState:
		var clone := ReapingState.new()
		clone.threshold_id = threshold_id; clone.is_active = is_active; clone.form_id = form_id; clone.writ_id = writ_id
		clone.retinue_ids = retinue_ids.duplicate(); clone.assignment_revision = assignment_revision; clone.cycle_phase_msec = cycle_phase_msec
		clone.completed_cycle_count = completed_cycle_count; clone.flow_carry_units = flow_carry_units.duplicate(true)
		clone.started_simulation_msec = started_simulation_msec; clone.last_configuration_change_simulation_msec = last_configuration_change_simulation_msec
		return clone

class ProgressionState:
	extends RefCounted
	## Stores global progression facts. Command-tether occupancy is derived from Reapings;
	## output access is global by output item ID, while per-source acquisition work remains
	## owned by each ThresholdState.channel_acquisition entry so later M04D slices can
	## advance or freeze sources without duplicating item-level unlock state.
	var command_tether_capacity: int = 0
	var unlocked_output_item_ids: Array[StringName] = []
	func _init(capacity := 0, unlocked_items: Array[StringName] = []) -> void:
		command_tether_capacity = capacity
		unlocked_output_item_ids = unlocked_items.duplicate()
		unlocked_output_item_ids.sort()
	func deep_clone() -> ProgressionState:
		return ProgressionState.new(command_tether_capacity, unlocked_output_item_ids)

class_name ReapingRateContextService
extends RefCounted

## Pure M04D3 rate-context, residual-signature, and acquisition-query owner.
##
## The service reads immutable content plus the supplied GameState snapshot and
## returns derived validation, continuity, rate-plan, and ETA data. It owns no
## authoritative gameplay state, performs no elapsed production, reads no clocks,
## files, scenes, reports, or platform state, and never mutates GameState. That
## separation lets assignment commands preserve residual work while simulation
## and presentation queries share the same baseline-derived output-channel plan.

const OK := &""
const REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED := &"REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED"
const ERR_CONTENT := &"RATE_CONTEXT_CONTENT_INVALID"
const ERR_OVERFLOW := &"RATE_CONTEXT_OVERFLOW"
const ERR_QUERY_INACTIVE := &"RATE_CONTEXT_QUERY_INACTIVE"
const ERR_NO_ACTIVE_ETA := &"RATE_CONTEXT_NO_ACTIVE_ETA"
const ETA_BASIS_CURRENT_RATE_CONTEXT := "CURRENT_RATE_CONTEXT"
const SUPPORTED_OUTPUT_CHANNEL_CONDITIONS := ["ALWAYS", "OUTPUT_ITEM", "OUTPUT_KIND", "THRESHOLD_HAS_ANY_TAG", "THRESHOLD_LIFECYCLE"]

var registry: ContentRegistry

func _init(content_registry: ContentRegistry) -> void:
	registry = content_registry

func loadout_identity(form_id: StringName, writ_id: StringName, retinue_ids: Array[StringName] = []) -> Dictionary:
	var retinues: Array[String] = []
	for retinue_id in retinue_ids:
		retinues.append(str(retinue_id))
	return {"form_id": str(form_id), "writ_id": str(writ_id), "ordered_retinue_ids": retinues, "retinue_ids": retinues}

func residual_signature(state: GameState, threshold_id: StringName, form_id: StringName) -> Dictionary:
	if registry == null or not registry.ready:
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "registry not ready"}
	var state_validation := GameStateValidator.validate(state, registry, true)
	if not state_validation.ok:
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": str(state_validation)}
	var form_result := registry.get_record(str(form_id))
	var threshold_result := registry.get_record(str(threshold_id))
	if not form_result.ok or not threshold_result.ok:
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "missing form or threshold"}
	var form: Dictionary = form_result.record
	var threshold: Dictionary = threshold_result.record
	var essence := CoreFlowKeys.find_single_essence_channel(registry, threshold_id, threshold)
	if not essence.ok:
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": str(essence)}
	var channel_periods := {}
	if state != null and state.thresholds.has(threshold_id):
		var threshold_state: GameState.ThresholdState = state.thresholds[threshold_id]
		var channel_ids := threshold_state.channel_acquisition.keys()
		channel_ids.sort()
		for channel_id in channel_ids:
			var relationship := OutputAccessService.validate_channel_relationship(registry, str(channel_id), "", str(threshold_id))
			if not relationship.ok:
				return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "invalid initialized channel relationship: %s" % channel_id}
			if int(relationship.channel.rate.period_msec) <= 0:
				return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "non-positive channel period: %s" % channel_id}
			channel_periods[str(channel_id)] = int(relationship.channel.rate.period_msec)
	if int(form.base_returned_souls_rate.period_msec) <= 0 or int(form.active_mastery_rate.period_msec) <= 0 or int(form.cycle_duration_msec) <= 0 or int(essence.channel.rate.period_msec) <= 0:
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "non-positive residual denominator"}
	var signature := {"returned_soul_period_msec": int(form.base_returned_souls_rate.period_msec), "returned_period_msec": int(form.base_returned_souls_rate.period_msec), "mastery_period_msec": int(form.active_mastery_rate.period_msec), "cycle_duration_msec": int(form.cycle_duration_msec), "essence_period_msec": int(essence.channel.rate.period_msec), "initialized_non_essence_channel_period_msec_by_channel_id": channel_periods, "channel_periods_msec": channel_periods}
	return {"ok": true, "success": true, "signature": signature}

func compare_residual_signatures(state: GameState, threshold_id: StringName, old_form_id: StringName, new_form_id: StringName) -> Dictionary:
	var old_sig := residual_signature(state, threshold_id, old_form_id)
	if not old_sig.ok: return old_sig
	var new_sig := residual_signature(state, threshold_id, new_form_id)
	if not new_sig.ok: return new_sig
	var mismatches := _signature_mismatches(old_sig.signature, new_sig.signature)
	if mismatches.is_empty():
		return {"ok": true, "success": true, "compatible": true, "code": OK, "error_code": OK, "developer_details": "", "mismatched_fields": [], "old_signature": old_sig.signature, "new_signature": new_sig.signature}
	return {"ok": false, "success": false, "compatible": false, "code": REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED, "error_code": REAPING_RATE_CONTEXT_NORMALIZATION_REQUIRED, "developer_details": "Rate-context normalization required for: %s" % ", ".join(mismatches), "mismatched_fields": mismatches, "old_signature": old_sig.signature, "new_signature": new_sig.signature}

func output_channel_rate_plan(threshold_id: StringName, form_id: StringName, channel_id: StringName, lifecycle_state: String) -> Dictionary:
	var form_result := registry.get_record(str(form_id))
	var threshold_result := registry.get_record(str(threshold_id))
	var channel_result := registry.get_record(str(channel_id))
	if not form_result.ok or not threshold_result.ok or not channel_result.ok:
		return {"ok": false, "code": ERR_CONTENT, "details": "missing content"}
	var form: Dictionary = form_result.record
	var threshold: Dictionary = threshold_result.record
	var channel: Dictionary = channel_result.record
	if channel.type != "channel" or not channel.enabled or channel.source_threshold_id != str(threshold_id):
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "invalid channel ownership"}
	var relationship := OutputAccessService.validate_channel_relationship(registry, str(channel_id), "", str(threshold_id))
	if not relationship.ok:
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "Essence or misowned channel is not an output-channel rate plan"}
	if lifecycle_state != "OVERDUE" and lifecycle_state != "SETTLED":
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "unsupported lifecycle: %s" % lifecycle_state}
	var baseline := int(channel.rate.rate_subunits_per_period)
	if baseline <= 0 or int(channel.rate.period_msec) <= 0:
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "non-positive channel rate"}
	var value := baseline
	var trace: Array = []
	# M04D3 modifiers are prospective: start from authored channel baseline every
	# time, then apply active Form Traits in authored order. A redispatch therefore
	# cannot multiply a previously-derived value and produce x1.44 from two x1.20
	# swaps.
	for trait_record in form.traits:
		for modifier_index in range(trait_record.modifiers.size()):
			var modifier: Dictionary = trait_record.modifiers[modifier_index]
			if modifier.metric != "OUTPUT_CHANNEL_RATE":
				continue
			if modifier.operation != "MULTIPLY" or modifier.scope != "OUTPUT_CHANNEL":
				return {"ok": false, "code": ERR_CONTENT, "details": "unsupported OUTPUT_CHANNEL_RATE modifier"}
			var applicability := _modifier_applicability(modifier, threshold, channel, lifecycle_state)
			if not applicability.ok:
				return applicability
			if not applicability.applies:
				continue
			var before := value
			var scaled := FixedPoint.multiply_scaled_floor(value, int(modifier.value_subunits))
			if not scaled.ok:
				return {"ok": false, "code": ERR_OVERFLOW, "details": "modifier overflow"}
			value = int(scaled.subunits)
			trace.append({"source_type": "FORM_TRAIT", "source_id": trait_record.id, "trait_id": trait_record.id, "modifier_index": modifier_index, "metric": modifier.metric, "operation": modifier.operation, "scope": modifier.scope, "condition": modifier.condition, "condition_values": modifier.condition_values.duplicate(), "multiplier_subunits": int(modifier.value_subunits), "rate_before_subunits_per_period": before, "rate_after_subunits_per_period": value, "rate_before": before, "rate_after": value})
	if lifecycle_state == "SETTLED":
		var settled := FixedPoint.multiply_scaled_floor(value, int(channel.settled_multiplier_subunits))
		if not settled.ok:
			return {"ok": false, "code": ERR_OVERFLOW, "details": "settled multiplier overflow"}
		value = int(settled.subunits)
	return {"ok": true, "success": true, "threshold_id": str(threshold_id), "channel_id": str(channel_id), "output_item_id": str(channel.output_item_id), "output_kind": str(channel.output_kind), "lifecycle_state": lifecycle_state, "baseline_rate_subunits_per_period": baseline, "effective_rate_subunits_per_period": value, "rate_subunits_per_period": value, "period_msec": int(channel.rate.period_msec), "lifecycle_multiplier_subunits": int(channel.settled_multiplier_subunits) if lifecycle_state == "SETTLED" else FixedPoint.SCALE, "applied_modifiers": trace, "modifier_trace": trace}

func query_acquisition(state: GameState, threshold_id: StringName, channel_id: StringName) -> Dictionary:
	if state == null or not state.thresholds.has(threshold_id):
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "missing threshold"}
	var channel_result := registry.get_record(str(channel_id))
	if not channel_result.ok or channel_result.record.type != "channel" or not channel_result.record.enabled:
		return {"ok": false, "success": false, "error_code": ERR_CONTENT, "code": ERR_CONTENT, "developer_details": "invalid channel"}
	var channel: Dictionary = channel_result.record
	var relationship := OutputAccessService.validate_channel_relationship(registry, str(channel_id), "", str(threshold_id))
	var threshold: GameState.ThresholdState = state.thresholds[threshold_id]
	if not relationship.ok or str(threshold.availability_state) != "AVAILABLE" or not threshold.channel_acquisition.has(channel_id):
		return _no_eta_query(threshold_id, channel_id, channel, threshold, "LOCKED_OR_UNINITIALIZED")
	var acq: GameState.ThresholdAcquisitionState = threshold.channel_acquisition[channel_id]
	var percent_tenths: int = min(999, (acq.progress_subunits * 1000) / FixedPoint.SCALE)
	var active: bool = state.reapings.has(threshold_id) and state.reapings[threshold_id].is_active
	var result := {"ok": true, "success": true, "error_code": OK, "developer_details": "", "threshold_id": str(threshold_id), "channel_id": str(channel_id), "output_item_id": str(channel.output_item_id), "loadout_identity": {}, "access_state": "INITIALIZED", "disclosure_state": str(channel.initial_discovery_state), "is_active": active, "lifecycle_state": str(threshold.lifecycle_state), "progress_subunits": acq.progress_subunits, "progress_tenths_percent": percent_tenths, "percent_tenths": percent_tenths, "rate_carry_units": acq.rate_carry_units, "rate_plan": {}, "eta_available": false, "eta_basis": ETA_BASIS_CURRENT_RATE_CONTEXT, "current_context_eta_msec": -1, "eta_msec": -1, "eta_display": eta_display(0)}
	if not active:
		return result
	var reaping: GameState.ReapingState = state.reapings[threshold_id]
	var plan := output_channel_rate_plan(threshold_id, reaping.form_id, channel_id, str(threshold.lifecycle_state))
	if not plan.ok: return plan
	result["loadout_identity"] = loadout_identity(reaping.form_id, reaping.writ_id, reaping.retinue_ids)
	result["rate_plan"] = plan
	var eta := _eta_msec_to_next_whole(acq.progress_subunits, acq.rate_carry_units, int(plan.rate_subunits_per_period), int(plan.period_msec))
	if not eta.ok: return eta
	result["eta_available"] = true
	result["current_context_eta_msec"] = int(eta.eta_msec)
	result["eta_msec"] = int(eta.eta_msec)
	result["eta_display"] = eta_display(int(eta.eta_msec))
	return result

func eta_display(eta_msec: int) -> Dictionary:
	var total_seconds := eta_msec / 1000
	if eta_msec > 0 and eta_msec % 1000 != 0:
		total_seconds += 1
	var units: Array = []
	if total_seconds >= 86400:
		units = [["DAY", total_seconds / 86400], ["HOUR", (total_seconds / 3600) % 24], ["MINUTE", (total_seconds / 60) % 60]]
	else:
		units = [["HOUR", total_seconds / 3600], ["MINUTE", (total_seconds / 60) % 60], ["SECOND", total_seconds % 60]]
	var parts: Array[String] = []
	var components: Array = []
	for unit in units:
		var value := int(unit[1])
		var label: String = str(unit[0]).to_lower()
		var word := label + ("" if value == 1 else "s")
		parts.append("%02d %s" % [value, word])
		components.append({"unit": unit[0], "value": value, "minimum_width": 2})
	return {"components": components, "english_text": ", ".join(parts)}

func _eta_msec_to_next_whole(progress_subunits: int, carry_units: int, rate: int, period: int) -> Dictionary:
	if progress_subunits < 0 or progress_subunits >= FixedPoint.SCALE:
		return {"ok": false, "code": ERR_CONTENT, "details": "invalid progress"}
	if carry_units < 0 or (period > 0 and carry_units >= period):
		return {"ok": false, "code": ERR_CONTENT, "details": "invalid carry"}
	if rate <= 0 or period <= 0:
		return {"ok": false, "code": ERR_CONTENT, "details": "non-positive rate"}
	var remaining := FixedPoint.SCALE - progress_subunits
	if remaining <= 0:
		return {"ok": true, "eta_msec": 0}
	# Need minimum e where floor((rate * e + carry) / period) >= remaining.
	# This is ceil((remaining * period - carry) / rate) with all residual units left
	# untouched; the query is a view and never rebases progress or carry.
	if remaining > FixedPoint.INT64_MAX / period:
		return {"ok": false, "code": ERR_OVERFLOW, "details": "eta numerator overflow"}
	var numerator := remaining * period - carry_units
	if numerator <= 0:
		return {"ok": true, "eta_msec": 0}
	if numerator > FixedPoint.INT64_MAX - rate + 1:
		return {"ok": false, "code": ERR_OVERFLOW, "details": "eta ceiling overflow"}
	return {"ok": true, "eta_msec": (numerator + rate - 1) / rate}

func _modifier_applicability(modifier: Dictionary, threshold: Dictionary, channel: Dictionary, lifecycle_state: String) -> Dictionary:
	# A modifier with metric OUTPUT_CHANNEL_RATE is relevant once the active Form
	# exposes it. Conditions approved for the broader content grammar but deferred
	# past M04D3 must therefore fail visibly instead of looking like an ordinary
	# non-matching condition; otherwise simulation and queries would quietly use
	# baseline rates for content that this slice cannot interpret.
	var operand_check := _validate_modifier_operands(modifier)
	if not operand_check.ok:
		return operand_check
	if not SUPPORTED_OUTPUT_CHANNEL_CONDITIONS.has(modifier.condition):
		return {"ok": false, "code": ERR_CONTENT, "details": "unsupported OUTPUT_CHANNEL_RATE condition: %s" % modifier.condition}
	match modifier.condition:
		"ALWAYS": return {"ok": true, "applies": true}
		"OUTPUT_ITEM": return {"ok": true, "applies": modifier.condition_values.has(channel.output_item_id)}
		"OUTPUT_KIND": return {"ok": true, "applies": modifier.condition_values.has(channel.output_kind)}
		"THRESHOLD_HAS_ANY_TAG":
			for tag in modifier.condition_values:
				if threshold.tags.has(tag): return {"ok": true, "applies": true}
			return {"ok": true, "applies": false}
		"THRESHOLD_LIFECYCLE": return {"ok": true, "applies": modifier.condition_values.has(lifecycle_state)}
	return {"ok": false, "code": ERR_CONTENT, "details": "unsupported OUTPUT_CHANNEL_RATE condition: %s" % modifier.condition}

func _signature_mismatches(old_signature: Dictionary, new_signature: Dictionary) -> Array[String]:
	var mismatches: Array[String] = []
	for field in ["returned_soul_period_msec", "mastery_period_msec", "cycle_duration_msec", "essence_period_msec"]:
		if int(old_signature.get(field, -1)) != int(new_signature.get(field, -1)):
			mismatches.append(field)
	var old_channels: Dictionary = old_signature.get("initialized_non_essence_channel_period_msec_by_channel_id", {})
	var new_channels: Dictionary = new_signature.get("initialized_non_essence_channel_period_msec_by_channel_id", {})
	var ids := {}
	for id in old_channels.keys(): ids[id] = true
	for id in new_channels.keys(): ids[id] = true
	var sorted_ids := ids.keys(); sorted_ids.sort()
	for id in sorted_ids:
		if int(old_channels.get(id, -1)) != int(new_channels.get(id, -1)):
			mismatches.append("channel_period_msec.%s" % id)
	mismatches.sort()
	return mismatches

func _no_eta_query(threshold_id: StringName, channel_id: StringName, channel: Dictionary, threshold: GameState.ThresholdState, access_state: String) -> Dictionary:
	return {"ok": true, "success": true, "error_code": OK, "developer_details": "", "threshold_id": str(threshold_id), "channel_id": str(channel_id), "output_item_id": str(channel.get("output_item_id", "")), "loadout_identity": {}, "access_state": access_state, "disclosure_state": str(channel.get("initial_discovery_state", "UNKNOWN")), "is_active": false, "lifecycle_state": str(threshold.lifecycle_state), "progress_subunits": 0, "progress_tenths_percent": 0, "percent_tenths": 0, "rate_plan": {}, "eta_available": false, "current_context_eta_msec": -1, "eta_msec": -1, "eta_basis": ETA_BASIS_CURRENT_RATE_CONTEXT, "eta_display": eta_display(0)}

func _validate_modifier_operands(modifier: Dictionary) -> Dictionary:
	var values: Array = modifier.condition_values
	match modifier.condition:
		"ALWAYS":
			if not values.is_empty(): return {"ok": false, "code": ERR_CONTENT, "details": "ALWAYS requires no operands"}
		"OUTPUT_ITEM", "OUTPUT_KIND", "THRESHOLD_HAS_ANY_TAG", "THRESHOLD_LIFECYCLE":
			if values.is_empty(): return {"ok": false, "code": ERR_CONTENT, "details": "%s requires operands" % modifier.condition}
	return {"ok": true}

class_name TimeReconciliationService
extends RefCounted

## Coordinates M01 foreground elapsed time and trusted-time reconciliation.
##
## The service owns no state itself.  It mutates caller-provided GameState and
## TimeAuthorityState only through explicit foreground and commit operations.  The
## planning method is non-mutating so later persistence can simulate offline
## results and save the anchor update in one transaction.

const OK := "OK"
const TIME_NEGATIVE_ELAPSED := "TIME_NEGATIVE_ELAPSED"
const TIME_OVERFLOW := "TIME_OVERFLOW"
const TIME_MONOTONIC_BACKWARDS := "TIME_MONOTONIC_BACKWARDS"
const TIME_UNAVAILABLE := "TIME_UNAVAILABLE"
const TIME_SAMPLE_MALFORMED := "TIME_SAMPLE_MALFORMED"
const TIME_SOURCE_MISMATCH := "TIME_SOURCE_MISMATCH"
const TIME_SAMPLE_BACKWARDS := "TIME_SAMPLE_BACKWARDS"
const TIME_SAMPLE_NOT_AHEAD := "TIME_SAMPLE_NOT_AHEAD"
const TIME_STALE_PLAN := "TIME_STALE_PLAN"
const TIME_INVALID_CAP := "TIME_INVALID_CAP"

var _last_monotonic_msec: int = -1

func observe_monotonic(now_msec: int) -> Dictionary:
	if now_msec < 0:
		return {"ok": false, "code": TIME_SAMPLE_MALFORMED, "elapsed_msec": 0}
	if _last_monotonic_msec < 0:
		_last_monotonic_msec = now_msec
		return {"ok": true, "code": OK, "elapsed_msec": 0}
	if now_msec < _last_monotonic_msec:
		return {"ok": false, "code": TIME_MONOTONIC_BACKWARDS, "elapsed_msec": 0}
	var elapsed_msec := now_msec - _last_monotonic_msec
	_last_monotonic_msec = now_msec
	return {"ok": true, "code": OK, "elapsed_msec": elapsed_msec}


func credit_foreground_elapsed(game_state: GameState, time_state: TimeAuthorityState, elapsed_msec: int) -> Dictionary:
	if elapsed_msec < 0:
		return {"ok": false, "code": TIME_NEGATIVE_ELAPSED}
	if time_state.has_anchor() and time_state.foreground_credited_since_anchor_msec > FixedPoint.INT64_MAX - elapsed_msec:
		return {"ok": false, "code": TIME_OVERFLOW}
	var advance_result := game_state.advance_simulation_time(elapsed_msec)
	if not advance_result.ok:
		return {"ok": false, "code": TIME_OVERFLOW}
	if time_state.has_anchor():
		time_state.foreground_credited_since_anchor_msec += elapsed_msec
	return {"ok": true, "code": OK, "simulation_time_msec": game_state.simulation_time_msec}


func plan_trusted_reconciliation(time_state: TimeAuthorityState, sample_value: TrustedTimeSample, offline_cap_msec: int) -> Dictionary:
	if offline_cap_msec < 0:
		return {"ok": false, "code": TIME_INVALID_CAP, "credited_msec": 0}
	if sample_value.status == TrustedTimeSample.STATUS_UNAVAILABLE:
		return _plan(false, TIME_UNAVAILABLE, 0, 0, 0, time_state, sample_value, false, true)
	if sample_value.status != TrustedTimeSample.STATUS_TRUSTED or sample_value.utc_msec < 0 or sample_value.source_id.is_empty():
		return _plan(false, TIME_SAMPLE_MALFORMED, 0, 0, 0, time_state, sample_value, false, false)
	if not time_state.has_anchor():
		return _plan(true, OK, 0, 0, 0, time_state, sample_value, true, false)
	if sample_value.source_id != time_state.trusted_source_id:
		return _plan(false, TIME_SOURCE_MISMATCH, 0, 0, 0, time_state, sample_value, false, false)
	if sample_value.utc_msec < time_state.trusted_anchor_utc_msec:
		return _plan(false, TIME_SAMPLE_BACKWARDS, 0, 0, 0, time_state, sample_value, false, false)
	var gross_gap_msec := sample_value.utc_msec - time_state.trusted_anchor_utc_msec
	if gross_gap_msec <= time_state.foreground_credited_since_anchor_msec:
		return _plan(true, TIME_SAMPLE_NOT_AHEAD, 0, gross_gap_msec, 0, time_state, sample_value, false, false)
	var uncredited_gap_msec := gross_gap_msec - time_state.foreground_credited_since_anchor_msec
	var credited_msec: int = min(uncredited_gap_msec, offline_cap_msec)
	var capped_out_msec: int = uncredited_gap_msec - credited_msec
	return _plan(true, OK, credited_msec, gross_gap_msec, capped_out_msec, time_state, sample_value, false, false)


func commit_trusted_reconciliation(game_state: GameState, time_state: TimeAuthorityState, plan: Dictionary) -> Dictionary:
	if not plan.get("ok", false):
		time_state.last_diagnostic_code = plan.get("code", TIME_SAMPLE_MALFORMED)
		if plan.get("set_pending", false):
			time_state.pending_reconciliation = true
		return {"ok": false, "code": plan.get("code", TIME_SAMPLE_MALFORMED)}
	if time_state.trusted_anchor_utc_msec != plan.previous_anchor_utc_msec or time_state.trusted_source_id != plan.previous_source_id or time_state.foreground_credited_since_anchor_msec != plan.previous_foreground_credited_since_anchor_msec:
		return {"ok": false, "code": TIME_STALE_PLAN}
	var advance_result := game_state.advance_simulation_time(plan.credited_msec)
	if not advance_result.ok:
		return {"ok": false, "code": TIME_OVERFLOW}
	if plan.establish_anchor or plan.credited_msec > 0:
		time_state.trusted_anchor_utc_msec = plan.sample_utc_msec
		time_state.trusted_source_id = plan.sample_source_id
		time_state.foreground_credited_since_anchor_msec = 0
		time_state.pending_reconciliation = false
	else:
		time_state.pending_reconciliation = false
	time_state.last_diagnostic_code = plan.code
	return {"ok": true, "code": plan.code, "credited_msec": plan.credited_msec, "simulation_time_msec": game_state.simulation_time_msec}


func _plan(ok_value: bool, code: String, credited_msec: int, gross_gap_msec: int, capped_out_msec: int, time_state: TimeAuthorityState, sample_value: TrustedTimeSample, establish_anchor: bool, set_pending: bool) -> Dictionary:
	return {
		"ok": ok_value,
		"code": code,
		"credited_msec": credited_msec,
		"gross_gap_msec": gross_gap_msec,
		"capped_out_msec": capped_out_msec,
		"sample_utc_msec": sample_value.utc_msec,
		"sample_source_id": sample_value.source_id,
		"previous_anchor_utc_msec": time_state.trusted_anchor_utc_msec,
		"previous_source_id": time_state.trusted_source_id,
		"previous_foreground_credited_since_anchor_msec": time_state.foreground_credited_since_anchor_msec,
		"establish_anchor": establish_anchor,
		"set_pending": set_pending,
	}

extends SceneTree

## Headless M01 deterministic trace.
## Prints a fixed trusted-time and fixed-point demonstration and exits nonzero if
## any value differs from the milestone contract.

const FixedPoint := preload("res://src/domain/fixed_point.gd")
const GameState := preload("res://src/domain/game_state.gd")
const TimeAuthorityState := preload("res://src/domain/time_authority_state.gd")
const TrustedTimeSample := preload("res://src/platform/time/trusted_time_sample.gd")
const TimeReconciliationService := preload("res://src/simulation/time_reconciliation_service.gd")

func _init() -> void:
	var failed := false
	failed = not _run_time_trace() or failed
	failed = not _run_fixed_point_trace() or failed
	quit(1 if failed else 0)

func _run_time_trace() -> bool:
	var game := GameState.new()
	var time := TimeAuthorityState.new()
	var service := TimeReconciliationService.new()
	var anchor := service.plan_trusted_reconciliation(time, TrustedTimeSample.trusted("FAKE", 1_000_000), 8 * 60 * 60 * 1000)
	service.commit_trusted_reconciliation(game, time, anchor)
	service.credit_foreground_elapsed(game, time, 10 * 60 * 1000)
	var one_hour := service.plan_trusted_reconciliation(time, TrustedTimeSample.trusted("FAKE", 1_000_000 + 60 * 60 * 1000), 8 * 60 * 60 * 1000)
	service.commit_trusted_reconciliation(game, time, one_hour)
	var repeat := service.plan_trusted_reconciliation(time, TrustedTimeSample.trusted("FAKE", 1_000_000 + 60 * 60 * 1000), 8 * 60 * 60 * 1000)
	print("M01 trusted-time trace: anchor_credit=%d foreground_credit=%d one_hour_uncredited=%d repeat_credit=%d" % [anchor.credited_msec, 600_000, one_hour.credited_msec, repeat.credited_msec])
	return anchor.credited_msec == 0 and one_hour.credited_msec == 50 * 60 * 1000 and repeat.credited_msec == 0 and game.simulation_time_msec == 60 * 60 * 1000

func _run_fixed_point_trace() -> bool:
	var period := 24 * 60 * 60 * 1000
	var six_hours := FixedPoint.accumulate_for_elapsed_msec(FixedPoint.SCALE, period, 6 * 60 * 60 * 1000, 0)
	var total := 0
	var carry := 0
	for _i in range(4):
		var part := FixedPoint.accumulate_for_elapsed_msec(FixedPoint.SCALE, period, 6 * 60 * 60 * 1000, carry)
		total += part.produced_subunits
		carry = part.carry_units
	var extracted := FixedPoint.extract_whole(total)
	print("M01 fixed-point trace: six_hour_subunits=%d whole_after_24h=%d residual_subunits=%d carry=%d" % [six_hours.produced_subunits, extracted.whole_units, extracted.remaining_subunits, carry])
	return six_hours.produced_subunits == 250_000 and extracted.whole_units == 1 and extracted.remaining_subunits == 0 and carry == 0

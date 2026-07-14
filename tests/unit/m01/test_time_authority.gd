extends GutTest

const GameStateScript := preload("res://src/domain/game_state.gd")
const TimeAuthorityStateScript := preload("res://src/domain/time_authority_state.gd")
const TrustedTimeSampleScript := preload("res://src/platform/time/trusted_time_sample.gd")
const TimeReconciliationServiceScript := preload("res://src/simulation/time_reconciliation_service.gd")

func test_monotonic_observation_contract() -> void:
	var service := TimeReconciliationServiceScript.new()
	assert_eq(service.observe_monotonic(100).elapsed_msec, 0)
	assert_eq(service.observe_monotonic(150).elapsed_msec, 50)
	var backwards := service.observe_monotonic(149)
	assert_false(backwards.ok)
	assert_eq(backwards.code, TimeReconciliationServiceScript.TIME_MONOTONIC_BACKWARDS)
	assert_eq(service.observe_monotonic(175).elapsed_msec, 25)

func test_anchor_foreground_gap_commit_and_repeat() -> void:
	var game := GameStateScript.new()
	var time := TimeAuthorityStateScript.new()
	var service := TimeReconciliationServiceScript.new()
	var anchor_plan := service.plan_trusted_reconciliation(time, TrustedTimeSampleScript.trusted("FAKE", 1_000_000), 3_600_000)
	assert_eq(anchor_plan.credited_msec, 0)
	assert_true(service.commit_trusted_reconciliation(game, time, anchor_plan).ok)
	assert_eq(time.trusted_anchor_utc_msec, 1_000_000)
	assert_true(service.credit_foreground_elapsed(game, time, 600_000).ok)
	assert_eq(time.foreground_credited_since_anchor_msec, 600_000)
	var plan := service.plan_trusted_reconciliation(time, TrustedTimeSampleScript.trusted("FAKE", 4_600_000), 3_600_000)
	assert_eq(plan.gross_gap_msec, 3_600_000)
	assert_eq(plan.credited_msec, 3_000_000)
	assert_true(service.commit_trusted_reconciliation(game, time, plan).ok)
	assert_eq(game.simulation_time_msec, 3_600_000)
	var repeat := service.plan_trusted_reconciliation(time, TrustedTimeSampleScript.trusted("FAKE", 4_600_000), 3_600_000)
	assert_eq(repeat.credited_msec, 0)
	assert_eq(repeat.code, TimeReconciliationServiceScript.TIME_SAMPLE_NOT_AHEAD)

func test_unavailable_mismatch_backwards_cap_and_stale_plan() -> void:
	var game := GameStateScript.new()
	var time := TimeAuthorityStateScript.new()
	var service := TimeReconciliationServiceScript.new()
	var unavailable := service.plan_trusted_reconciliation(time, TrustedTimeSampleScript.unavailable("FAKE"), 1000)
	assert_false(unavailable.ok)
	service.commit_trusted_reconciliation(game, time, unavailable)
	assert_true(time.pending_reconciliation)
	var anchor := service.plan_trusted_reconciliation(time, TrustedTimeSampleScript.trusted("A", 10_000), 1000)
	assert_true(service.commit_trusted_reconciliation(game, time, anchor).ok)
	var mismatch := service.plan_trusted_reconciliation(time, TrustedTimeSampleScript.trusted("B", 11_000), 1000)
	assert_eq(mismatch.code, TimeReconciliationServiceScript.TIME_SOURCE_MISMATCH)
	service.commit_trusted_reconciliation(game, time, mismatch)
	assert_true(time.pending_reconciliation)
	time.pending_reconciliation = false
	var backwards := service.plan_trusted_reconciliation(time, TrustedTimeSampleScript.trusted("A", 9_999), 1000)
	assert_eq(backwards.code, TimeReconciliationServiceScript.TIME_SAMPLE_BACKWARDS)
	service.commit_trusted_reconciliation(game, time, backwards)
	assert_true(time.pending_reconciliation)
	time.pending_reconciliation = false
	var capped := service.plan_trusted_reconciliation(time, TrustedTimeSampleScript.trusted("A", 20_000), 4_000)
	assert_eq(capped.credited_msec, 4_000)
	assert_eq(capped.capped_out_msec, 6_000)
	time.foreground_credited_since_anchor_msec = 1
	assert_eq(service.commit_trusted_reconciliation(game, time, capped).code, TimeReconciliationServiceScript.TIME_STALE_PLAN)

func test_foreground_invalid_elapsed_does_not_mutate() -> void:
	var game := GameStateScript.new()
	var time := TimeAuthorityStateScript.new()
	var service := TimeReconciliationServiceScript.new()
	var result := service.credit_foreground_elapsed(game, time, -1)
	assert_false(result.ok)
	assert_eq(game.simulation_time_msec, 0)

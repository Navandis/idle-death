extends GutTest

const FixedPoint := preload("res://src/domain/fixed_point.gd")

func test_scale_and_whole_extraction() -> void:
	assert_eq(FixedPoint.SCALE, 1_000_000)
	var whole := FixedPoint.from_whole(3)
	assert_true(whole.ok)
	assert_eq(whole.subunits, 3_000_000)
	var extracted := FixedPoint.extract_whole(2_500_001)
	assert_eq(extracted.whole_units, 2)
	assert_eq(extracted.remaining_subunits, 500_001)

func test_one_item_per_24_hours_accumulates_exactly_and_chunks_equally() -> void:
	var period := 86_400_000
	var six_hours := FixedPoint.accumulate_for_elapsed_msec(FixedPoint.SCALE, period, 21_600_000, 0)
	assert_true(six_hours.ok)
	assert_eq(six_hours.produced_subunits, 250_000)
	assert_eq(six_hours.carry_units, 0)
	var carry := 0
	var total := 0
	for _i in range(4):
		var part := FixedPoint.accumulate_for_elapsed_msec(FixedPoint.SCALE, period, 21_600_000, carry)
		total += part.produced_subunits
		carry = part.carry_units
	assert_eq(total, FixedPoint.SCALE)
	assert_eq(carry, 0)
	var extracted := FixedPoint.extract_whole(total)
	assert_eq(extracted.whole_units, 1)
	assert_eq(extracted.remaining_subunits, 0)

func test_one_item_per_8_hours_and_residual_carry() -> void:
	var period := 28_800_000
	var first := FixedPoint.accumulate_for_elapsed_msec(FixedPoint.SCALE, period, 1, 0)
	assert_eq(first.produced_subunits, 0)
	assert_eq(first.carry_units, 1_000_000)
	var whole := FixedPoint.accumulate_for_elapsed_msec(FixedPoint.SCALE, period, period - 1, first.carry_units)
	assert_eq(whole.produced_subunits, FixedPoint.SCALE)
	assert_eq(whole.carry_units, 0)

func test_high_value_final_fit_and_overflow_failure() -> void:
	var final_fit := FixedPoint.accumulate_for_elapsed_msec(9_000_000_000_000_000_000, 9_000_000_000_000_000_000, 9_000_000_000_000_000_000, 0)
	assert_true(final_fit.ok)
	assert_eq(final_fit.produced_subunits, 9_000_000_000_000_000_000)
	var overflow := FixedPoint.accumulate_for_elapsed_msec(FixedPoint.INT64_MAX, 1, 2, 0)
	assert_false(overflow.ok)
	assert_eq(overflow.code, FixedPoint.ERR_OVERFLOW)

func test_invalid_inputs_are_typed_failures() -> void:
	assert_eq(FixedPoint.accumulate_for_elapsed_msec(1, 0, 1).code, FixedPoint.ERR_INVALID_PERIOD)
	assert_eq(FixedPoint.accumulate_for_elapsed_msec(-1, 1, 1).code, FixedPoint.ERR_NEGATIVE_INPUT)
	assert_eq(FixedPoint.accumulate_for_elapsed_msec(1, 10, 1, 10).code, FixedPoint.ERR_INVALID_CARRY)

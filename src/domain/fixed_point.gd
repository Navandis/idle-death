class_name FixedPoint
extends RefCounted

## Central fixed-point arithmetic for authoritative fractional prototype state.
##
## The class owns the single M01 scale: one whole fractional unit is exactly
## 1,000,000 subunits.  It does not own inventory, backlog, command tethers, or
## other discrete gameplay counts; those remain ordinary whole integers.  All
## flow helpers in this milestone accept non-negative values and return typed
## dictionaries so expected validation and overflow failures never wrap or
## partially mutate caller-owned progress.

const SCALE: int = 1_000_000
const INT64_MAX: int = 9_223_372_036_854_775_807
const INT64_MIN: int = -9_223_372_036_854_775_808

const OK := "OK"
const ERR_NEGATIVE_INPUT := "FIXED_POINT_NEGATIVE_INPUT"
const ERR_INVALID_PERIOD := "FIXED_POINT_INVALID_PERIOD"
const ERR_OVERFLOW := "FIXED_POINT_OVERFLOW"
const ERR_INVALID_CARRY := "FIXED_POINT_INVALID_CARRY"

static func ok(fields: Dictionary = {}) -> Dictionary:
	var result := {"ok": true, "code": OK}
	for key in fields.keys():
		result[key] = fields[key]
	return result


static func fail(code: String) -> Dictionary:
	return {"ok": false, "code": code}


## Converts a whole fractional-unit count into subunits with overflow checking.
static func from_whole(whole_units: int) -> Dictionary:
	if whole_units < 0:
		return fail(ERR_NEGATIVE_INPUT)
	if whole_units > INT64_MAX / SCALE:
		return fail(ERR_OVERFLOW)
	return ok({"subunits": whole_units * SCALE})


## Extracts whole units from subunit progress and preserves the exact residual.
static func extract_whole(progress_subunits: int) -> Dictionary:
	if progress_subunits < 0:
		return fail(ERR_NEGATIVE_INPUT)
	return ok({
		"whole_units": progress_subunits / SCALE,
		"remaining_subunits": progress_subunits % SCALE,
	})


## Adds non-negative subunits with explicit overflow reporting.
static func add_subunits(left_subunits: int, right_subunits: int) -> Dictionary:
	if left_subunits < 0 or right_subunits < 0:
		return fail(ERR_NEGATIVE_INPUT)
	if left_subunits > INT64_MAX - right_subunits:
		return fail(ERR_OVERFLOW)
	return ok({"subunits": left_subunits + right_subunits})


## Multiplies two scaled non-negative fixed-point values and floors once.
static func multiply_scaled_floor(value_subunits: int, multiplier_subunits: int) -> Dictionary:
	if value_subunits < 0 or multiplier_subunits < 0:
		return fail(ERR_NEGATIVE_INPUT)
	if value_subunits != 0 and multiplier_subunits > INT64_MAX / value_subunits:
		return fail(ERR_OVERFLOW)
	return ok({"subunits": (value_subunits * multiplier_subunits) / SCALE})


## Adds non-negative signed-64 integers with explicit overflow reporting.
static func add_int64(left: int, right: int) -> Dictionary:
	if left < 0 or right < 0:
		return fail(ERR_NEGATIVE_INPUT)
	if left > INT64_MAX - right:
		return fail(ERR_OVERFLOW)
	return ok({"value": left + right})


## Accumulates a non-negative integer-millisecond rate with an explicit period.
##
## `rate_subunits_per_period` is produced once per `period_msec`.  `carry_units`
## is the exact numerator remainder from the same flow key and must be in
## `[0, period_msec)`.  The method returns produced subunits and the next carry;
## callers own adding produced subunits to their authoritative progress.  The
## implementation decomposes multiplication so high-value cases whose naive
## `rate * elapsed` intermediate would overflow can still succeed when the final
## quotient fits in signed 64-bit.
static func accumulate_for_elapsed_msec(rate_subunits_per_period: int, period_msec: int, elapsed_msec: int, carry_units: int = 0) -> Dictionary:
	if rate_subunits_per_period < 0 or elapsed_msec < 0:
		return fail(ERR_NEGATIVE_INPUT)
	if period_msec <= 0:
		return fail(ERR_INVALID_PERIOD)
	if carry_units < 0 or carry_units >= period_msec:
		return fail(ERR_INVALID_CARRY)

	var whole_periods: int = elapsed_msec / period_msec
	var remainder_msec: int = elapsed_msec % period_msec
	var produced_result := _checked_multiply(rate_subunits_per_period, whole_periods)
	if not produced_result.ok:
		return produced_result
	var produced_subunits: int = produced_result.value

	var fractional_result := _mul_add_divmod(rate_subunits_per_period, remainder_msec, carry_units, period_msec)
	if not fractional_result.ok:
		return fractional_result
	if produced_subunits > INT64_MAX - fractional_result.quotient:
		return fail(ERR_OVERFLOW)
	return ok({
		"produced_subunits": produced_subunits + fractional_result.quotient,
		"carry_units": fractional_result.remainder,
	})


static func _checked_multiply(a: int, b: int) -> Dictionary:
	if a < 0 or b < 0:
		return fail(ERR_NEGATIVE_INPUT)
	if a != 0 and b > INT64_MAX / a:
		return fail(ERR_OVERFLOW)
	return {"ok": true, "value": a * b}


# Computes floor((a * b + addend) / divisor) and the corresponding remainder
# without constructing the potentially overflowing product.  Each doubled
# contribution is reduced by `divisor`, and the quotient contribution is checked
# before it is added to the result.
static func _mul_add_divmod(a: int, b: int, addend: int, divisor: int) -> Dictionary:
	var quotient: int = addend / divisor
	var remainder: int = addend % divisor
	var term_quotient: int = a / divisor
	var term_remainder: int = a % divisor
	var multiplier: int = b
	while multiplier > 0:
		if (multiplier & 1) == 1:
			if quotient > INT64_MAX - term_quotient:
				return fail(ERR_OVERFLOW)
			quotient += term_quotient
			remainder += term_remainder
			if remainder >= divisor:
				quotient += remainder / divisor
				remainder = remainder % divisor
				if quotient < 0:
					return fail(ERR_OVERFLOW)
		multiplier = multiplier >> 1
		if multiplier > 0:
			if term_quotient > INT64_MAX / 2:
				return fail(ERR_OVERFLOW)
			term_quotient *= 2
			term_remainder *= 2
			if term_remainder >= divisor:
				term_quotient += term_remainder / divisor
				term_remainder = term_remainder % divisor
			if term_quotient < 0:
				return fail(ERR_OVERFLOW)
	return {"ok": true, "quotient": quotient, "remainder": remainder}

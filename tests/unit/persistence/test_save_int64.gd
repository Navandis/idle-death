extends GutTest

func test_boundary_values_round_trip() -> void:
	for value in [0, 42, 9007199254740991, 9007199254740992, 1710000000000, 123456, SaveInt64.INT64_MAX, SaveInt64.INT64_MIN]:
		var parsed := SaveInt64.parse(SaveInt64.format(value), true, "field")
		assert_true(parsed.ok)
		assert_eq(parsed.value, value)

func test_malformed_values_rejected() -> void:
	for text in ["", "+1", " 1", "1 ", "01", "-0", "1.0", "1e3", "1,000", "abc", "9223372036854775808", "-9223372036854775809"]:
		assert_false(SaveInt64.parse(text, true, "field").ok, text)

func test_json_number_rejected_for_integer_field() -> void:
	assert_eq(SaveInt64.parse(1, false, "schema_version").code, SaveInt64.ERR_NOT_STRING)

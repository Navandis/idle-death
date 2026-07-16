extends GutTest

func _snapshot(anchor := false) -> Dictionary:
	var g := GameState.new(1234)
	var t := TimeAuthorityState.new()
	if anchor:
		t.trusted_anchor_utc_msec = 1710000000000
		t.trusted_source_id = "fake"
		t.foreground_credited_since_anchor_msec = 25
	return SaveSchemaMapper.runtime_to_snapshot(g, t, 7, "prototype-content-r1")

func test_unanchored_runtime_wire_mapping_round_trips() -> void:
	var snapshot := _snapshot(false)
	assert_false(snapshot.time_authority.has_trusted_anchor)
	assert_eq(snapshot.time_authority.trusted_anchor_utc_msec, "0")
	var runtime := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_true(runtime.ok)
	assert_eq(runtime.time_authority_state.trusted_anchor_utc_msec, -1)
	assert_eq(runtime.time_authority_state.foreground_credited_since_anchor_msec, 0)

func test_anchored_runtime_round_trips() -> void:
	var runtime := SaveSchemaMapper.snapshot_to_runtime(_snapshot(true))
	assert_true(runtime.ok)
	assert_eq(runtime.time_authority_state.trusted_anchor_utc_msec, 1710000000000)
	assert_eq(runtime.time_authority_state.trusted_source_id, "fake")

func test_schema_rejects_cross_field_contradictions_and_unknown_codec() -> void:
	var s := _snapshot(false)
	s.time_authority.trusted_source_id = "bad"
	assert_eq(SaveSchemaValidator.validate_v2(s).code, SaveSchemaValidator.ERR_CROSS_FIELD)
	s = _snapshot(false)
	s.codec_id = "OTHER"
	assert_eq(SaveSchemaValidator.validate_v2(s).code, SaveSchemaValidator.ERR_CODEC)

func test_json_codec_is_deterministic_and_rejects_objects() -> void:
	var codec := JsonSaveCodec.new()
	var a := codec.encode(_snapshot(true))
	var b := codec.encode(_snapshot(true))
	assert_true(a.ok)
	assert_eq(a.bytes, b.bytes)
	var bad := _snapshot(false)
	bad["object"] = RefCounted.new()
	assert_eq(codec.encode(bad).code, JsonSaveCodec.ERR_UNSUPPORTED_VARIANT)

func test_json_numeric_integer_field_decodes_then_schema_rejects() -> void:
	var codec := JsonSaveCodec.new()
	var decoded := codec.decode('{"codec_id":"JSON_V1","schema_version":1,"save_revision":"1","content_revision":"x","last_offline_resolution_id":"","metadata":{},"game_state":{"simulation_time_msec":"0"},"time_authority":{"has_trusted_anchor":false,"trusted_anchor_utc_msec":"0","trusted_source_id":"","foreground_credited_since_anchor_msec":"0","pending_trusted_reconciliation":false,"last_sample_diagnostic_code":"TIME_OK"}}'.to_utf8_buffer())
	assert_true(decoded.ok)
	assert_eq(SaveSchemaValidator.validate_v1(decoded.snapshot).code, SaveInt64.ERR_NOT_STRING)

extends GutTest

const V1_FIXTURE := "res://tests/fixtures/saves/schema_v1_foundation.json"
const V2_FIXTURE := "res://tests/fixtures/saves/schema_v2_m04a_representative.json"

func _read_fixture(path: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	var decoded := JsonSaveCodec.new().decode(bytes)
	assert_true(decoded.ok, path)
	return decoded.snapshot

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func test_frozen_v1_fixture_validates_and_migrates_preserving_authority() -> void:
	var v1 := _read_fixture(V1_FIXTURE)
	assert_true(SaveSchemaValidator.validate_v1(v1).ok)
	var migrated := SaveMigrationRegistry.new().migrate(v1, SaveEnvelope.SCHEMA_VERSION_V1)
	assert_true(migrated.ok)
	assert_eq(migrated.snapshot.schema_version, "4")
	assert_eq(migrated.snapshot.save_revision, v1.save_revision)
	assert_eq(migrated.snapshot.content_revision, v1.content_revision)
	assert_eq(migrated.snapshot.time_authority, v1.time_authority)
	assert_eq(migrated.snapshot.last_offline_resolution_id, v1.last_offline_resolution_id)
	assert_eq(migrated.snapshot.metadata, v1.metadata)
	assert_eq(migrated.snapshot.game_state.inventory, {"entries": {}})
	assert_eq(migrated.snapshot.game_state.forms, {})
	assert_eq(migrated.snapshot.game_state.thresholds, {})
	assert_eq(migrated.snapshot.game_state.reapings, {})
	assert_eq(migrated.snapshot.game_state.progression, {"command_tether_capacity": "0", "unlocked_output_item_ids": []})
	v1.metadata.fixture.name = "mutated"
	assert_eq(migrated.snapshot.metadata.fixture.name, "schema_v1_foundation")

func test_representative_v2_fixture_validates_maps_and_round_trips() -> void:
	var snapshot := _read_fixture(V2_FIXTURE)
	assert_true(SaveSchemaValidator.validate_v2(snapshot).ok)
	var runtime := SaveSchemaMapper.snapshot_to_runtime(snapshot)
	assert_true(runtime.ok)
	runtime.game_state.progression.unlocked_output_item_ids.append(&"SOUL_CALLING_SOLDIER")
	assert_true(GameStateValidator.validate(runtime.game_state, _registry()).ok)
	var remapped := SaveSchemaMapper.runtime_to_snapshot(runtime.game_state, runtime.time_authority_state, runtime.save_revision, runtime.content_revision)
	assert_true(SaveSchemaValidator.validate_current(remapped).ok)
	var encoded := JsonSaveCodec.new().encode(remapped)
	assert_true(encoded.ok)
	var decoded := JsonSaveCodec.new().decode(encoded.bytes)
	assert_true(decoded.ok)
	assert_true(SaveSchemaValidator.validate_current(decoded.snapshot).ok)
	var runtime_again := SaveSchemaMapper.snapshot_to_runtime(decoded.snapshot)
	assert_true(runtime_again.ok)
	assert_eq(runtime_again.game_state.inventory.entries["RES_ESSENCE"].reservations["REC_WEAVE_REMEMBERED"], 25)
	assert_eq(runtime_again.game_state.reapings[&"THR_GLOAMWOOD"].flow_carry_units["FLOW_TEST"], 4)

func test_runtime_stringname_keys_are_normalized_to_json_string_keys() -> void:
	var runtime := SaveSchemaMapper.snapshot_to_runtime(_read_fixture(V2_FIXTURE))
	assert_true(runtime.ok)
	runtime.game_state.inventory.entries.erase("RES_ESSENCE")
	runtime.game_state.inventory.entries[&"RES_ESSENCE"] = GameState.InventoryEntryState.new(3, {&"REC_NAMES_KEPT": 1})
	runtime.game_state.reapings[&"THR_GLOAMWOOD"].flow_carry_units = {&"FLOW_STRINGNAME": 9}
	runtime.game_state.progression.unlocked_output_item_ids.append(&"SOUL_CALLING_SOLDIER")
	var snapshot := SaveSchemaMapper.runtime_to_snapshot(runtime.game_state, runtime.time_authority_state, runtime.save_revision, runtime.content_revision)
	assert_true(snapshot.game_state.inventory.entries.has("RES_ESSENCE"))
	assert_true(snapshot.game_state.inventory.entries.RES_ESSENCE.reservations.has("REC_NAMES_KEPT"))
	assert_true(snapshot.game_state.reapings.THR_GLOAMWOOD.flow_carry_units.has("FLOW_STRINGNAME"))
	assert_true(JsonSaveCodec.new().encode(snapshot).ok)

func test_schema_rejects_malformed_nested_keys_types_and_numeric_integers() -> void:
	var snapshot := _read_fixture(V2_FIXTURE)
	snapshot.game_state.inventory.entries.RES_ESSENCE.erase("total")
	assert_eq(SaveSchemaValidator.validate_v2(snapshot).code, SaveSchemaValidator.ERR_KEY_SET)
	snapshot = _read_fixture(V2_FIXTURE)
	snapshot.game_state.forms.FORM_MAN_AT_ARMS.awakened = "true"
	assert_eq(SaveSchemaValidator.validate_v2(snapshot).code, SaveSchemaValidator.ERR_TYPE)
	for path in [
		["game_state", "simulation_time_msec"],
		["game_state", "inventory", "entries", "RES_ESSENCE", "total"],
		["game_state", "forms", "FORM_MAN_AT_ARMS", "mastery_subunits"],
		["game_state", "thresholds", "THR_GLOAMWOOD", "remaining_backlog"],
		["game_state", "thresholds", "THR_GLOAMWOOD", "channel_acquisition", "CHANNEL_GLOAMWOOD_SOLDIER_SOULS", "progress_subunits"],
		["game_state", "reapings", "THR_GLOAMWOOD", "assignment_revision"],
		["game_state", "progression", "command_tether_capacity"],
	]:
		snapshot = _read_fixture(V2_FIXTURE)
		_set_path(snapshot, path, 1)
		assert_false(SaveSchemaValidator.validate_v2(snapshot).ok, str(path))

func test_migration_error_cases() -> void:
	var invalid_v1 := _read_fixture(V1_FIXTURE)
	invalid_v1.game_state.simulation_time_msec = "bad"
	assert_false(SaveMigrationRegistry.new().migrate(invalid_v1, SaveEnvelope.SCHEMA_VERSION_V1).ok)
	assert_eq(SaveMigrationRegistry.new().migrate({}, SaveEnvelope.CURRENT_SCHEMA_VERSION + 1).code, SaveMigrationRegistry.ERR_FUTURE_SCHEMA)
	var missing := SaveMigrationRegistry.new()
	missing._steps.clear()
	assert_eq(missing.migrate(_read_fixture(V1_FIXTURE), SaveEnvelope.SCHEMA_VERSION_V1).code, SaveMigrationRegistry.ERR_MISSING_STEP)
	var failed := SaveMigrationRegistry.new()
	failed.register_step(SaveEnvelope.SCHEMA_VERSION_V1, func(_s): return {"ok": false, "code": "TEST_FAIL"})
	assert_eq(failed.migrate(_read_fixture(V1_FIXTURE), SaveEnvelope.SCHEMA_VERSION_V1).code, SaveMigrationRegistry.ERR_FAILED_STEP)

func _set_path(data: Dictionary, path: Array, value: Variant) -> void:
	var cursor: Variant = data
	for index in range(path.size() - 1):
		cursor = cursor[path[index]]
	cursor[path[path.size() - 1]] = value

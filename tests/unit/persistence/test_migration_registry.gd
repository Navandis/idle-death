extends GutTest

func test_test_only_migration_step_advances_to_v1() -> void:
	var registry := SaveMigrationRegistry.new()
	registry.register_step(0, func(s): s["schema_version"] = "1"; return {"ok": true, "snapshot": s})
	var old := SaveSchemaMapper.runtime_to_snapshot(GameState.new(), TimeAuthorityState.new(), 1)
	old.schema_version = "0"
	var result := registry.migrate(old, 0)
	assert_true(result.ok)
	assert_eq(result.snapshot.schema_version, "1")

func test_missing_and_future_migrations_fail() -> void:
	var registry := SaveMigrationRegistry.new()
	assert_eq(registry.migrate({}, 0).code, SaveMigrationRegistry.ERR_MISSING_STEP)
	assert_eq(registry.migrate({}, 2).code, SaveMigrationRegistry.ERR_FUTURE_SCHEMA)

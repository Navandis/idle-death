extends GutTest

var storage: MemorySaveStorage
var files: SaveFileSet
var service: SaveService

func before_each() -> void:
	storage = MemorySaveStorage.new()
	files = SaveFileSet.new("mem://root", "save")
	service = SaveService.new(storage, files)

func test_first_second_save_backup_and_highest_revision_selection() -> void:
	assert_true(service.save_runtime(GameState.new(1), TimeAuthorityState.new(), 1, "prototype-content-r1").ok)
	assert_true(storage.exists(files.primary_path))
	assert_true(service.save_runtime(GameState.new(2), TimeAuthorityState.new(), 2, "prototype-content-r1").ok)
	assert_true(storage.exists(files.backup_path))
	var loaded := service.load_runtime()
	assert_true(loaded.ok)
	assert_eq(loaded.save_revision, 2)
	# Filename role is not authoritative; backup with higher revision wins.
	storage.files[files.backup_path] = JsonSaveCodec.new().encode(SaveSchemaMapper.runtime_to_snapshot(GameState.new(3), TimeAuthorityState.new(), 3, "prototype-content-r1")).bytes
	loaded = service.load_runtime()
	assert_eq(loaded.save_revision, 3)
	assert_eq(loaded.selected_role, "backup")

func test_corrupt_primary_falls_back_to_backup_and_is_retained() -> void:
	assert_true(service.save_runtime(GameState.new(1), TimeAuthorityState.new(), 1, "prototype-content-r1").ok)
	assert_true(service.save_runtime(GameState.new(2), TimeAuthorityState.new(), 2, "prototype-content-r1").ok)
	var corrupt := PackedByteArray([123, 98, 97, 100])
	storage.files[files.primary_path] = corrupt
	var loaded := service.load_runtime()
	assert_true(loaded.ok)
	assert_eq(loaded.save_revision, 1)
	assert_eq(loaded.selected_role, "backup")
	assert_eq(storage.files[files.primary_path], corrupt)
	assert_gt(loaded.diagnostics.size(), 0)

func test_both_invalid_preserved() -> void:
	storage.files[files.primary_path] = PackedByteArray([1, 2, 3])
	storage.files[files.backup_path] = PackedByteArray([4, 5])
	var loaded := service.load_runtime()
	assert_false(loaded.ok)
	assert_true(storage.exists(files.primary_path))
	assert_true(storage.exists(files.backup_path))

func test_failure_injection_leaves_previous_valid_snapshot() -> void:
	assert_true(service.save_runtime(GameState.new(1), TimeAuthorityState.new(), 1, "prototype-content-r1").ok)
	for operation in ["write", "copy", "rename"]:
		storage.fail_once(operation)
		assert_false(service.save_runtime(GameState.new(2), TimeAuthorityState.new(), 2, "prototype-content-r1").ok, operation)
		var loaded := service.load_runtime()
		assert_true(loaded.ok, operation)
		assert_eq(loaded.game_state.simulation_time_msec, 1, operation)

func test_invalid_existing_primary_is_preserved_before_replacement() -> void:
	storage.files[files.primary_path] = "not json".to_utf8_buffer()
	assert_true(service.save_runtime(GameState.new(5), TimeAuthorityState.new(), 1, "prototype-content-r1").ok)
	assert_true(storage.exists(files.suspect_path(0, 0)))
	assert_eq(storage.files[files.suspect_path(0, 0)].get_string_from_utf8(), "not json")

func test_reconciliation_candidate_does_not_mutate_original_on_save_failure() -> void:
	var game := GameState.new(10)
	var time := TimeAuthorityState.new()
	time.trusted_anchor_utc_msec = 1000
	time.trusted_source_id = "fake"
	var plan := TimeReconciliationService.new().plan_trusted_reconciliation(time, TrustedTimeSample.trusted("fake", 1500), 1000)
	plan["content_revision"] = "prototype-content-r1"
	storage.fail_once("write")
	var result := service.persist_reconciliation_candidate(game, time, plan, 1)
	assert_false(result.ok)
	assert_eq(game.simulation_time_msec, 10)
	assert_eq(time.trusted_anchor_utc_msec, 1000)
	assert_true(service.persist_reconciliation_candidate(game, time, plan, 1).ok)
	var loaded := service.load_runtime()
	assert_eq(loaded.game_state.simulation_time_msec, 510)

extends GutTest

const CATALOG_PATH := "res://content/prototype_content_catalog.tres"

func test_registry_owns_content_revision_compatibility_after_schema_load() -> void:
	var registry := ContentRegistry.build(ResourceLoader.load(CATALOG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE))
	assert_true(registry.ready)
	assert_true(registry.is_save_revision_compatible("prototype-content-r1"))
	assert_true(registry.is_save_revision_compatible("prototype-m02"))
	assert_false(registry.is_save_revision_compatible("prototype-unknown"))

func test_save_runtime_requires_explicit_content_revision() -> void:
	var storage := preload("res://tests/support/memory_save_storage.gd").new()
	var file_set := SaveFileSet.new("user://content-compat")
	var service := SaveService.new(storage, file_set)
	var result := service.save_runtime(GameState.new(0), TimeAuthorityState.new(), 1, "")
	assert_false(result.ok)
	assert_eq(result.code, "SAVE_CONTENT_REVISION_REQUIRED")
	assert_true(service.save_runtime(GameState.new(0), TimeAuthorityState.new(), 1, "prototype-content-r1").ok)

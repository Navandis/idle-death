extends GutTest

const Catalog := preload("res://content/prototype_content_catalog.tres")

func test_current_and_m02_revisions_are_compatible_before_simulation() -> void:
	var registry := ContentRegistry.build(Catalog)
	assert_true(registry.ready)
	assert_true(ContentRegistry.is_save_revision_compatible("prototype-content-r1"))
	assert_true(ContentRegistry.is_save_revision_compatible("prototype-m02"))
	assert_false(ContentRegistry.is_save_revision_compatible("prototype-unknown"))

func test_save_runtime_requires_explicit_content_revision() -> void:
	var storage := preload("res://tests/support/memory_save_storage.gd").new()
	var file_set := SaveFileSet.new("user://save.json")
	var service := SaveService.new(storage, file_set)
	var result := service.save_runtime(GameState.new(0), TimeAuthorityState.new(), 1, "")
	assert_false(result.ok)
	assert_eq(result.code, "SAVE_CONTENT_REVISION_REQUIRED")

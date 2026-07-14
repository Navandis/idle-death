extends GutTest

const ContentRegistryScript := preload("res://src/content/content_registry.gd")
const CatalogResource := preload("res://content/prototype_content_catalog.tres")

func test_production_catalog_builds_with_required_counts_and_revision() -> void:
	var registry := ContentRegistry.build(CatalogResource)
	assert_true(registry.ready, "catalog should build: %s" % [registry.diagnostics])
	assert_eq(registry.ids().size(), 60)
	assert_true(ContentRegistry.is_save_revision_compatible("prototype-content-r1"))
	assert_true(ContentRegistry.is_save_revision_compatible("prototype-m02"))
	assert_false(ContentRegistry.is_save_revision_compatible("unknown"))

func test_representative_normalized_values_and_essence_ids() -> void:
	var registry := ContentRegistry.build(CatalogResource)
	assert_true(registry.ready, "catalog should build")
	var essence: Dictionary = registry.get_record("CHANNEL_GLOAMWOOD_ESSENCE").record
	assert_eq(essence.data.output_item_id, "RES_ESSENCE")
	assert_eq(essence.data.rate_per_period, 1000000)
	assert_eq(essence.data.period_msec, 10000)
	var scribe: Dictionary = registry.get_record("CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS").record
	assert_eq(scribe.data.period_msec, 28800000)
	var man: Dictionary = registry.get_record("CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS").record
	assert_eq(man.data.period_msec, 86400000)

func test_form_traits_are_data_not_display_name_branches() -> void:
	var registry := ContentRegistry.build(CatalogResource)
	var maa: Dictionary = registry.get_record("FORM_MAN_AT_ARMS").record
	var scribe: Dictionary = registry.get_record("FORM_SCRIBE").record
	assert_eq(maa.data.traits[0].id, "TRAIT_OLD_DRILL")
	assert_eq(scribe.data.traits[0].id, "TRAIT_UNCLOSED_LEDGER")
	assert_has(maa.data.slot_affinities, "MARTIAL")
	assert_has(scribe.data.slot_affinities, "SPECIALIST")

func test_source_resource_mutation_does_not_change_registry_record() -> void:
	var registry := ContentRegistry.build(CatalogResource)
	var before: String = registry.get_record("FORM_SCRIBE").record.display_name
	var mutable_catalog: ContentCatalog = load("res://content/prototype_content_catalog.tres")
	mutable_catalog.definitions[7].display_name = "Renamed In Inspector"
	assert_eq(registry.get_record("FORM_SCRIBE").record.display_name, before)

func test_invalid_duplicate_and_deprecated_essence_are_aggregated() -> void:
	var catalog: ContentCatalog = ContentCatalog.new()
	catalog.terminology = CatalogResource.terminology
	catalog.definitions = CatalogResource.definitions.duplicate()
	var duplicate := ContentDefinition.new()
	duplicate.id = "RES_ESSENCE"
	duplicate.kind = "item"
	duplicate.display_name = "Corrupted Essence"
	catalog.definitions.append(duplicate)
	var registry := ContentRegistry.build(catalog)
	assert_false(registry.ready)
	assert_gt(registry.diagnostics.size(), 1)
	assert_eq(registry.get_record("RES_ESSENCE").ok, false)

func test_unknown_lookup_returns_error() -> void:
	var registry := ContentRegistry.build(CatalogResource)
	assert_false(registry.get_record("FORM_MISSING").ok)
	assert_false(registry.get_term("TERM_MISSING").ok)

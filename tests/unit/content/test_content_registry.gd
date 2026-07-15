extends GutTest

const CATALOG_PATH := "res://content/prototype_content_catalog.tres"

const APPROVED_IDS := [
	"FORM_MAN_AT_ARMS", "FORM_SCRIBE",
	"RES_ESSENCE", "RES_PROVISIONS", "STORE_RATIONS", "SOUL_CALLING_SOLDIER", "SOUL_FORM_SCRIBE", "SOUL_FORM_MAN_AT_ARMS",
	"THR_GLOAMWOOD", "THR_BROKEN_WATCH", "CHANNEL_GLOAMWOOD_ESSENCE", "CHANNEL_GLOAMWOOD_SOLDIER_SOULS", "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "CHANNEL_BROKEN_WATCH_ESSENCE", "CHANNEL_BROKEN_WATCH_PROVISIONS", "CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS",
	"WRIT_EMERGENCY_FIRST_RETURN", "WRIT_STANDARD", "RET_SOLDIER_COMPANY", "HALL_ARCHIVE", "HALL_LARDER", "RECIPE_LARDER_PROVISIONS_TO_RATIONS",
	"REC_WEAVE_REMEMBERED", "REC_MUSTER_REMEMBERED", "REC_QUICKER_RECKONING", "REC_NAMES_KEPT", "REC_OPEN_LEDGERS",
	"MS_GLOAMWOOD_REAPING_1000", "MS_GLOAMWOOD_REAPING_2500", "MS_GLOAMWOOD_REAPING_5000", "MS_REGION_REAPING_10000", "MS_REGION_REAPING_25000", "MS_THRESHOLD_FIRST_SETTLEMENT",
	"GUA_ARCHIVE_WEAVE_COST_FLOOR", "GUA_SOLDIER_SOULS_12", "GUA_MUSTER_COST_FLOOR", "GUA_SCRIBE_SOUL_1", "GUA_SCRIBE_AWAKENING_COST_FLOOR", "GUA_PROVISIONS_ONBOARDING_FLOOR",
	"RESONANCE_GLOAMWOOD_5000_MINOR", "RESONANCE_REGION_10000",
	"TUT_00_BOOT", "TUT_01_WINDOW", "TUT_02_DIRECT_REAP", "TUT_03_SOULS_RETURN", "TUT_04_FIRST_DISPATCH", "TUT_05_ARCHIVE", "TUT_06_SOULWEAVE", "TUT_07_RETINUE", "TUT_08_SCRIBE", "TUT_09_SECOND_THRESHOLD", "TUT_10_DISCOVERY", "TUT_11_LARDER", "TUT_12_SEAL_CHOICE", "TUT_13_COMPLETE",
	"CHAR_DEATH", "CHAR_EUSTACE", "CHAR_MAN_AT_ARMS", "DIALOGUE_OPENING_AWAKENING", "DIALOGUE_FOUR_RETURNS_AND_SEALS"]

const REMOVED_IDS := ["SOUL_SOLDIER", "RES_RATIONS", "THR_GLOAMWOOD_HAMLET", "WRIT_EMERGENCY", "RECIPE_PROVISIONS_TO_RATIONS", "REC_FIRST_SEAL_RESONANCE", "REC_DRILL_MEMORY", "REC_SUPPLY_CACHE", "REC_PATROL_ROUTES", "REC_LEDGER_MARGINALIA", "GUARANTEE_OPENING_FOUR_SOULS", "RESONANCE_FIRST_SEAL_MINOR", "RESONANCE_SECOND_SEAL_ESSENCE", "TUT_OPENING"]

func test_production_catalog_exact_ids_terms_groups_and_revision() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	assert_true(registry.ready, "catalog diagnostics: %s" % [registry.diagnostics])
	var expected := APPROVED_IDS.duplicate(); expected.sort()
	assert_eq(registry.ids(), expected)
	assert_eq(registry.content_revision, "prototype-content-r1")
	assert_eq(registry.compatible_save_revisions, ["prototype-content-r1", "prototype-m02"])
	assert_true(registry.is_save_revision_compatible("prototype-content-r1"))
	assert_true(registry.is_save_revision_compatible("prototype-m02"))
	assert_false(registry.is_save_revision_compatible("prototype-unknown"))
	var counts := registry.group_counts()
	assert_eq(counts.items, 6)
	assert_eq(counts.forms, 2)
	assert_eq(counts.output_channels, 6)
	assert_eq(counts.tutorial_steps, 14)
	for term_id in ContentRegistry.REQUIRED_TERMS:
		assert_true(registry.get_term(term_id).ok, "term missing: %s" % term_id)

func test_removed_replacement_ids_are_absent() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	assert_true(registry.ready)
	for removed_id in REMOVED_IDS:
		assert_false(registry.get_record(removed_id).ok, "removed ID should not resolve: %s" % removed_id)

func test_exact_normalized_scaffold_values() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	var gloamwood: Dictionary = registry.get_record("THR_GLOAMWOOD").record
	assert_eq(gloamwood.settled_multiplier_subunits, 250000)
	var essence: Dictionary = registry.get_record("CHANNEL_GLOAMWOOD_ESSENCE").record
	assert_eq(essence.output_item_id, "RES_ESSENCE")
	assert_eq(essence.rate.rate_subunits_per_period, 1000000)
	assert_eq(essence.rate.period_msec, 10000)
	assert_eq(registry.get_record("CHANNEL_GLOAMWOOD_SOLDIER_SOULS").record.rate.period_msec, 300000)
	assert_eq(registry.get_record("CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS").record.rate.period_msec, 28800000)
	assert_eq(registry.get_record("CHANNEL_BROKEN_WATCH_PROVISIONS").record.rate.period_msec, 30000)
	assert_eq(registry.get_record("CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS").record.rate.period_msec, 86400000)
	var recipe: Dictionary = registry.get_record("RECIPE_LARDER_PROVISIONS_TO_RATIONS").record
	assert_eq(recipe.input.item_id, "RES_PROVISIONS")
	assert_eq(recipe.input.quantity, 10)
	assert_eq(recipe.output.item_id, "STORE_RATIONS")
	assert_eq(recipe.output.quantity, 10)
	assert_eq(recipe.duration_msec, 120000)
	assert_eq(recipe.default_target_quantity, 50)
	var retinue: Dictionary = registry.get_record("RET_SOLDIER_COMPANY").record
	assert_eq(retinue.required_items[0].item_id, "SOUL_CALLING_SOLDIER")
	assert_eq(retinue.required_items[0].quantity, 12)
	assert_eq(retinue.support_item_id, "STORE_RATIONS")
	assert_eq(retinue.reduced_support_floor_subunits, 500000)

func test_form_traits_modifiers_and_rename_isolation() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	var maa: Dictionary = registry.get_record("FORM_MAN_AT_ARMS").record
	var scribe: Dictionary = registry.get_record("FORM_SCRIBE").record
	assert_eq(maa.traits[0].id, "TRAIT_OLD_DRILL")
	assert_eq(maa.traits[0].modifiers[0].value_subunits, 1150000)
	assert_eq(scribe.traits[0].id, "TRAIT_UNCLOSED_LEDGER")
	assert_eq(scribe.traits[0].modifiers[0].metric, "DISCOVERY_RATE")
	assert_eq(scribe.traits[0].modifiers[0].value_subunits, 2000000)
	assert_eq(scribe.traits[0].modifiers[1].metric, "FORECAST_UNCERTAINTY")
	assert_eq(scribe.traits[0].modifiers[1].value_subunits, 500000)
	var before: String = scribe.traits[0].display_name
	var mutable_catalog: ContentCatalog = _fresh_catalog()
	mutable_catalog.forms[1].traits[0].display_name = "Renamed Ledger"
	assert_eq(registry.get_record("FORM_SCRIBE").record.traits[0].display_name, before)

func test_term_and_recollection_rename_isolation() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	var threshold_before: String = registry.get_term("TERM_THRESHOLD").term.fallback_text
	var recollection_before: String = registry.get_record("REC_OPEN_LEDGERS").record.display_name
	var mutable_catalog: ContentCatalog = _fresh_catalog()
	mutable_catalog.terminology.terms[4].fallback_text = "Passage"
	mutable_catalog.recollections[4].display_name = "Renamed Recollection"
	assert_eq(registry.get_term("TERM_THRESHOLD").term.fallback_text, threshold_before)
	assert_eq(registry.get_record("REC_OPEN_LEDGERS").record.display_name, recollection_before)
	assert_true(registry.is_save_revision_compatible("prototype-m02"))

func test_normalized_records_contain_no_floats() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	for id in registry.ids():
		assert_false(_contains_float(registry.get_record(id).record), "normalized record contains float: %s" % id)

func test_invalid_duplicate_wrong_prefix_missing_reference_and_bad_tokens_fail_all_or_nothing() -> void:
	var catalog: ContentCatalog = _fresh_catalog().duplicate()
	catalog.forms = _fresh_catalog().forms.duplicate()
	var duplicate: FormDefinition = _fresh_catalog().forms[0].duplicate()
	duplicate.id = "FORM_SCRIBE"
	catalog.forms.append(duplicate)
	catalog.output_channels = _fresh_catalog().output_channels.duplicate()
	var bad_channel: OutputChannelDefinition = catalog.output_channels[0].duplicate()
	bad_channel.id = "channel_bad"
	bad_channel.source_threshold_id = "THR_MISSING"
	bad_channel.rate.period_msec = 0
	catalog.output_channels[0] = bad_channel
	catalog.retinues = _fresh_catalog().retinues.duplicate()
	var bad_retinue: RetinueDefinition = catalog.retinues[0].duplicate()
	bad_retinue.required_items = [ItemAmountDefinition.new()]
	bad_retinue.required_items[0].item_id = "SOUL_CALLING_SOLDIER"
	bad_retinue.required_items[0].quantity = 11
	bad_retinue.modifiers[0].metric = "BAD_METRIC"
	catalog.retinues[0] = bad_retinue
	var registry := ContentRegistry.build(catalog)
	assert_false(registry.ready)
	assert_gt(registry.diagnostics.size(), 4)
	assert_false(registry.get_record("FORM_SCRIBE").ok)

func test_invalid_recipe_revision_term_and_deprecated_essence_fail() -> void:
	var catalog: ContentCatalog = _fresh_catalog().duplicate()
	catalog.compatible_save_revisions = ["prototype-m02", "prototype-m02"]
	catalog.recipes = _fresh_catalog().recipes.duplicate()
	var recipe: RecipeDefinition = catalog.recipes[0].duplicate()
	recipe.input.quantity = -1
	recipe.output.item_id = "RES_RATIONS"
	catalog.recipes[0] = recipe
	catalog.items = _fresh_catalog().items.duplicate()
	var item: ItemDefinition = catalog.items[0].duplicate()
	item.id = "RES_CORRUPTED_ESSENCE"
	item.display_name = "Corrupted Essence"
	catalog.items[0] = item
	catalog.terminology = _fresh_catalog().terminology.duplicate()
	catalog.terminology.terms = _fresh_catalog().terminology.terms.duplicate()
	catalog.terminology.terms.remove_at(0)
	var registry := ContentRegistry.build(catalog)
	assert_false(registry.ready)
	assert_gt(registry.diagnostics.size(), 4)

func test_decimal_rounding_and_overflow_validation() -> void:
	var catalog: ContentCatalog = _fresh_catalog().duplicate()
	catalog.output_channels = _fresh_catalog().output_channels.duplicate()
	var rounded: OutputChannelDefinition = catalog.output_channels[0].duplicate()
	rounded.rate.amount_per_period = 0.0000014
	catalog.output_channels[0] = rounded
	var registry := ContentRegistry.build(catalog)
	assert_true(registry.ready, "rounding catalog diagnostics: %s" % [registry.diagnostics])
	assert_eq(registry.get_record("CHANNEL_GLOAMWOOD_ESSENCE").record.rate.rate_subunits_per_period, 1)
	rounded.rate.amount_per_period = INF
	registry = ContentRegistry.build(catalog)
	assert_false(registry.ready)

func _contains_float(value) -> bool:
	if typeof(value) == TYPE_FLOAT:
		return true
	if typeof(value) == TYPE_DICTIONARY:
		for key in value.keys():
			if _contains_float(value[key]): return true
	if typeof(value) == TYPE_ARRAY:
		for item in value:
			if _contains_float(item): return true
	return false

func _fresh_catalog() -> ContentCatalog:
	return ResourceLoader.load(CATALOG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)

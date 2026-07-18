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
	assert_eq(registry.content_revision, "prototype-content-r2")
	assert_eq(registry.compatible_save_revisions, ["prototype-content-r1", "prototype-content-r2", "prototype-m02"])
	assert_true(registry.is_save_revision_compatible("prototype-content-r1"))
	assert_true(registry.is_save_revision_compatible("prototype-m02"))
	assert_false(registry.is_save_revision_compatible("prototype-unknown"))
	var counts := registry.group_counts()
	assert_eq(counts.items, 6)
	assert_eq(counts.forms, 2)
	assert_eq(counts.output_channels, 6)
	assert_eq(counts.tutorial_steps, 14)
	for term_id in ContentRegistry.REQUIRED_TERMS:
		var term: Dictionary = registry.get_term(term_id).term
		assert_ne(term.singular_display_name, "", "singular term missing: %s" % term_id)
		assert_ne(term.plural_display_name, "", "plural term missing: %s" % term_id)

func test_removed_replacement_ids_are_absent() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	assert_true(registry.ready)
	for removed_id in REMOVED_IDS:
		assert_false(registry.get_record(removed_id).ok, "removed ID should not resolve: %s" % removed_id)

func test_thresholds_channels_and_recipe_match_semantic_contract() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	assert_true(registry.ready)
	var gloamwood: Dictionary = registry.get_record("THR_GLOAMWOOD").record
	assert_eq(gloamwood.display_name, "Gloamwood Hamlet")
	assert_eq(gloamwood.standing_backlog, 1000000)
	assert_eq(gloamwood.tags, ["TAG_FOREST", "TAG_SETTLEMENT"])
	assert_eq(gloamwood.channel_ids, ["CHANNEL_GLOAMWOOD_ESSENCE", "CHANNEL_GLOAMWOOD_SOLDIER_SOULS", "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"])
	assert_eq(gloamwood.settled_multiplier_subunits, 250000)
	var broken: Dictionary = registry.get_record("THR_BROKEN_WATCH").record
	assert_eq(broken.display_name, "Broken Watch")
	assert_eq(broken.standing_backlog, 250000)
	assert_eq(broken.tags, ["TAG_ROAD", "TAG_SETTLEMENT", "TAG_MARTIAL"])
	assert_eq(broken.channel_ids, ["CHANNEL_BROKEN_WATCH_ESSENCE", "CHANNEL_BROKEN_WATCH_PROVISIONS", "CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"])
	_assert_channel(registry, "CHANNEL_GLOAMWOOD_ESSENCE", "CHARTED", "NONE", "", false, 10000)
	_assert_channel(registry, "CHANNEL_GLOAMWOOD_SOLDIER_SOULS", "UNKNOWN", "COMMON", "Common source", false, 300000)
	_assert_channel(registry, "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "UNKNOWN", "UNCOMMON", "Uncommon source", true, 28800000)
	_assert_channel(registry, "CHANNEL_BROKEN_WATCH_ESSENCE", "CHARTED", "NONE", "", false, 10000)
	_assert_channel(registry, "CHANNEL_BROKEN_WATCH_PROVISIONS", "UNKNOWN", "COMMON", "Common source", false, 30000)
	_assert_channel(registry, "CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS", "UNKNOWN", "UNCOMMON", "Uncommon source", true, 86400000)
	assert_false(registry.channel_shows_acquisition_progress("CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "UNKNOWN"))
	assert_true(registry.channel_shows_acquisition_progress("CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "IDENTIFIED"))
	var recipe: Dictionary = registry.get_record("RECIPE_LARDER_PROVISIONS_TO_RATIONS").record
	assert_eq(recipe.input.item_id, "RES_PROVISIONS")
	assert_eq(recipe.input.quantity, 10)
	assert_eq(recipe.output.item_id, "STORE_RATIONS")
	assert_eq(recipe.output.quantity, 10)
	assert_eq(recipe.duration_msec, 120000)
	assert_eq(recipe.default_target_quantity, 50)

func test_modifiers_and_rename_isolation_use_explicit_operands() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	var maa: Dictionary = registry.get_record("FORM_MAN_AT_ARMS").record
	var scribe: Dictionary = registry.get_record("FORM_SCRIBE").record
	assert_eq(maa.traits[0].modifiers[0].condition_values, ["TAG_SETTLEMENT", "TAG_MARTIAL"])
	assert_eq(maa.traits[0].modifiers[1].condition_values, ["MARTIAL"])
	assert_eq(scribe.traits[0].modifiers[0].metric, "DISCOVERY_RATE")
	assert_eq(scribe.traits[0].modifiers[0].value_subunits, 2000000)
	assert_eq(scribe.traits[0].modifiers[1].metric, "FORECAST_UNCERTAINTY")
	assert_eq(scribe.traits[0].modifiers[1].value_subunits, 500000)
	var retinue: Dictionary = registry.get_record("RET_SOLDIER_COMPANY").record
	assert_eq(retinue.modifiers[0].condition_values, ["MARTIAL"])
	assert_eq(retinue.support_item_id, "STORE_RATIONS")
	assert_eq(retinue.reduced_support_floor_subunits, 500000)
	var names_kept: Dictionary = registry.get_record("REC_NAMES_KEPT").record
	assert_eq(names_kept.modifiers[0].metric, "OUTPUT_CHANNEL_RATE")
	assert_eq(names_kept.modifiers[0].condition, "OUTPUT_KIND")
	assert_eq(names_kept.modifiers[0].condition_values, ["WHOLE_SOUL"])
	var before: String = scribe.traits[0].display_name
	var mutable_catalog: ContentCatalog = _fresh_catalog()
	mutable_catalog.forms[1].traits[0].display_name = "Renamed Ledger"
	assert_eq(registry.get_record("FORM_SCRIBE").record.traits[0].display_name, before)

func test_milestones_guarantees_and_resonances_match_semantic_contract() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	_assert_milestone(registry, "MS_GLOAMWOOD_REAPING_1000", [], [], ["GUA_SOLDIER_SOULS_12", "GUA_MUSTER_COST_FLOOR"], "")
	_assert_milestone(registry, "MS_GLOAMWOOD_REAPING_2500", [], [], ["GUA_SCRIBE_SOUL_1", "GUA_SCRIBE_AWAKENING_COST_FLOOR"], "")
	_assert_milestone(registry, "MS_GLOAMWOOD_REAPING_5000", [], ["FORM_SCRIBE"], [], "RESONANCE_GLOAMWOOD_5000_MINOR")
	_assert_milestone(registry, "MS_REGION_REAPING_10000", ["MS_GLOAMWOOD_REAPING_5000"], [], [], "RESONANCE_REGION_10000")
	_assert_milestone(registry, "MS_THRESHOLD_FIRST_SETTLEMENT", [], [], [], "")
	assert_eq(registry.get_record("MS_THRESHOLD_FIRST_SETTLEMENT").record.subject_id, "")
	assert_eq(registry.get_record("GUA_ARCHIVE_WEAVE_COST_FLOOR").record.source_definition_ids, ["HALL_ARCHIVE", "REC_WEAVE_REMEMBERED"])
	assert_eq(registry.get_record("GUA_MUSTER_COST_FLOOR").record.derived_preview_quantity, 25)
	assert_eq(registry.get_record("GUA_SCRIBE_AWAKENING_COST_FLOOR").record.derived_preview_quantity, 50)
	assert_eq(registry.get_record("GUA_PROVISIONS_ONBOARDING_FLOOR").record.derived_preview_quantity, 36)
	var minor: Dictionary = registry.get_record("RESONANCE_GLOAMWOOD_5000_MINOR").record
	assert_eq(minor.effects[0].kind, "RECORD_RESONANCE")
	assert_eq(minor.effects[0].target_ids, ["RESONANCE_GLOAMWOOD_5000_MINOR"])
	assert_eq(minor.effects[1].kind, "UNLOCK_THRESHOLD")
	assert_eq(minor.effects[1].target_ids, ["THR_BROKEN_WATCH"])
	assert_eq(minor.effects[2].kind, "ADD_COMMAND_TETHERS")
	assert_eq(minor.effects[2].quantity, 1)
	var regional: Dictionary = registry.get_record("RESONANCE_REGION_10000").record
	assert_eq(regional.rewards[0].item_id, "RES_ESSENCE")
	assert_eq(regional.rewards[0].quantity, 50)
	assert_eq(regional.effects[1].kind, "EXPOSE_RECOLLECTIONS")
	assert_eq(regional.effects[1].target_ids, ["REC_QUICKER_RECKONING", "REC_NAMES_KEPT", "REC_OPEN_LEDGERS"])

func test_derived_guarantee_preview_follows_source_cost_edits() -> void:
	var catalog: ContentCatalog = _fresh_catalog().duplicate()
	catalog.recollections = _fresh_catalog().recollections.duplicate()
	var muster: RecollectionDefinition = catalog.recollections[1].duplicate(true)
	muster.costs[0].quantity = 30
	catalog.recollections[1] = muster
	var registry := ContentRegistry.build(catalog)
	assert_true(registry.ready, "derived diagnostics: %s" % [registry.diagnostics])
	assert_eq(registry.get_record("GUA_MUSTER_COST_FLOOR").record.derived_preview_quantity, 30)

func test_term_and_recollection_rename_isolation() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	var threshold_before: Dictionary = registry.get_term("TERM_THRESHOLD").term
	var recollection_before: String = registry.get_record("REC_OPEN_LEDGERS").record.display_name
	var mutable_catalog: ContentCatalog = _fresh_catalog()
	mutable_catalog.terminology.terms[4].singular_display_name = "Passage"
	mutable_catalog.terminology.terms[4].plural_display_name = "Passages"
	mutable_catalog.recollections[4].display_name = "Renamed Recollection"
	assert_eq(registry.get_term("TERM_THRESHOLD").term.singular_display_name, threshold_before.singular_display_name)
	assert_eq(registry.get_term("TERM_THRESHOLD").term.plural_display_name, threshold_before.plural_display_name)
	assert_eq(registry.get_record("REC_OPEN_LEDGERS").record.display_name, recollection_before)
	assert_true(registry.is_save_revision_compatible("prototype-m02"))

func test_normalized_records_contain_no_floats() -> void:
	var registry := ContentRegistry.build(_fresh_catalog())
	for id in registry.ids():
		assert_false(_contains_float(registry.get_record(id).record), "normalized record contains float: %s" % id)

func test_invalid_semantic_content_fails_all_or_nothing() -> void:
	var catalog: ContentCatalog = _fresh_catalog().duplicate()
	catalog.thresholds = _fresh_catalog().thresholds.duplicate()
	var bad_threshold: ThresholdDefinition = catalog.thresholds[0].duplicate()
	bad_threshold.standing_backlog = 10000
	catalog.thresholds[0] = bad_threshold
	catalog.output_channels = _fresh_catalog().output_channels.duplicate()
	var bad_channel: OutputChannelDefinition = catalog.output_channels[0].duplicate()
	bad_channel.id = "channel_bad"
	bad_channel.frequency_tier = "RARE"
	bad_channel.show_acquisition_progress = true
	bad_channel.output_kind = "RESOURCE"
	catalog.output_channels[0] = bad_channel
	catalog.recollections = _fresh_catalog().recollections.duplicate()
	var bad_rec: RecollectionDefinition = catalog.recollections[3].duplicate(true)
	bad_rec.modifiers[0].condition_values = []
	catalog.recollections[3] = bad_rec
	catalog.milestones = _fresh_catalog().milestones.duplicate()
	var bad_ms: MilestoneDefinition = catalog.milestones[2].duplicate()
	bad_ms.required_awakened_form_ids = []
	catalog.milestones[2] = bad_ms
	catalog.guarantees = _fresh_catalog().guarantees.duplicate()
	var bad_guarantee: GuaranteeDefinition = catalog.guarantees[2].duplicate()
	bad_guarantee.minimum_amount = 25
	bad_guarantee.source_definition_ids = []
	catalog.guarantees[2] = bad_guarantee
	catalog.resonances = _fresh_catalog().resonances.duplicate()
	var bad_resonance: ResonanceDefinition = catalog.resonances[0].duplicate(true)
	bad_resonance.effects[0].target_ids = ["THR_BROKEN_WATCH"]
	catalog.resonances[0] = bad_resonance
	var registry := ContentRegistry.build(catalog)
	assert_false(registry.ready)
	assert_gt(registry.diagnostics.size(), 8)
	assert_false(registry.get_record("THR_GLOAMWOOD").ok)

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

func _assert_channel(registry: ContentRegistry, id: String, discovery: String, tier: String, label: String, progress: bool, period_msec: int) -> void:
	var channel: Dictionary = registry.get_record(id).record
	assert_eq(channel.initial_discovery_state, discovery)
	assert_eq(channel.frequency_tier, tier)
	assert_eq(channel.identified_frequency_label, label)
	assert_eq(channel.show_acquisition_progress, progress)
	assert_eq(channel.rate.period_msec, period_msec)

func _assert_milestone(registry: ContentRegistry, id: String, prereq: Array, forms: Array, guarantees: Array, resonance_id: String) -> void:
	var milestone: Dictionary = registry.get_record(id).record
	assert_eq(milestone.prerequisite_ids, prereq)
	assert_eq(milestone.required_awakened_form_ids, forms)
	assert_eq(milestone.guarantee_ids, guarantees)
	assert_eq(milestone.resonance_id, resonance_id)

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

extends SceneTree

## Headless M03 trace that asserts the approved typed content contract.

func _init() -> void:
	var catalog: ContentCatalog = load("res://content/prototype_content_catalog.tres")
	var registry := ContentRegistry.build(catalog)
	_assert(registry.ready, "registry builds: %s" % [registry.diagnostics])
	_assert(registry.ids() == _sorted(ContentRegistry.APPROVED_IDS), "exact approved ID set")
	_assert(registry.content_revision == "prototype-content-r1", "current revision")
	_assert(registry.compatible_save_revisions == ["prototype-content-r1", "prototype-m02"], "compatible revisions")
	_assert(registry.is_save_revision_compatible("prototype-m02"), "M02 compatibility")
	_assert(not registry.is_save_revision_compatible("unknown"), "unknown revision rejected")
	var counts := registry.group_counts()
	_assert(counts.items == 6 and counts.forms == 2 and counts.output_channels == 6 and counts.tutorial_steps == 14, "typed group counts")
	_assert(ContentRegistry.REQUIRED_TERMS.size() == 20, "twenty terms")
	for term_id in ContentRegistry.REQUIRED_TERMS:
		var term: Dictionary = registry.get_term(term_id).term
		_assert(term.singular_display_name != "" and term.plural_display_name != "", "term %s singular/plural" % term_id)
	print("M03_TRACE revision=%s compatible=%s total=%d terms=%d" % [registry.content_revision, registry.compatible_save_revisions, registry.ids().size(), ContentRegistry.REQUIRED_TERMS.size()])
	print("M03_TRACE groups=%s" % [counts])
	_assert_thresholds(registry)
	_assert_channels(registry)
	_assert_modifiers(registry)
	_assert_milestones_guarantees_resonances(registry)
	_assert_rename_and_override_isolation(catalog, registry)
	_assert_dynamic_guarantee_preview()
	_assert_duplicate_id_failure()
	print("M03_TRACE PASS")
	quit(0)

func _assert_thresholds(registry: ContentRegistry) -> void:
	var gloamwood: Dictionary = registry.get_record("THR_GLOAMWOOD").record
	var broken: Dictionary = registry.get_record("THR_BROKEN_WATCH").record
	_assert(gloamwood.display_name == "Gloamwood Hamlet" and gloamwood.standing_backlog == 1000000, "Gloamwood backlog/name")
	_assert(gloamwood.tags == ["TAG_FOREST", "TAG_SETTLEMENT"], "Gloamwood tags")
	_assert(broken.display_name == "Broken Watch" and broken.standing_backlog == 250000, "Broken Watch backlog/name")
	_assert(broken.tags == ["TAG_ROAD", "TAG_SETTLEMENT", "TAG_MARTIAL"], "Broken Watch tags")
	print("M03_TRACE thresholds Gloamwood=%s BrokenWatch=%s" % [gloamwood, broken])

func _assert_channels(registry: ContentRegistry) -> void:
	var expected := {
		"CHANNEL_GLOAMWOOD_ESSENCE": ["CHARTED", "NONE", "", false, 10000],
		"CHANNEL_GLOAMWOOD_SOLDIER_SOULS": ["UNKNOWN", "COMMON", "Common source", false, 300000],
		"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS": ["UNKNOWN", "UNCOMMON", "Uncommon source", true, 28800000],
		"CHANNEL_BROKEN_WATCH_ESSENCE": ["CHARTED", "NONE", "", false, 10000],
		"CHANNEL_BROKEN_WATCH_PROVISIONS": ["UNKNOWN", "COMMON", "Common source", false, 30000],
		"CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS": ["UNKNOWN", "UNCOMMON", "Uncommon source", true, 86400000],
	}
	for id in expected.keys():
		var channel: Dictionary = registry.get_record(id).record
		var e: Array = expected[id]
		_assert(channel.initial_discovery_state == e[0], "%s discovery" % id)
		_assert(channel.frequency_tier == e[1] and channel.identified_frequency_label == e[2], "%s frequency" % id)
		_assert(channel.show_acquisition_progress == e[3] and channel.rate.period_msec == e[4], "%s progress/period" % id)
		print("M03_TRACE channel=%s discovery=%s frequency=%s label='%s' progress=%s period=%d" % [id, channel.initial_discovery_state, channel.frequency_tier, channel.identified_frequency_label, channel.show_acquisition_progress, channel.rate.period_msec])
	_assert(not registry.channel_shows_acquisition_progress("CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "UNKNOWN"), "progress hidden before identification")
	_assert(registry.channel_shows_acquisition_progress("CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "IDENTIFIED"), "progress visible after identification")

func _assert_modifiers(registry: ContentRegistry) -> void:
	var maa: Dictionary = registry.get_record("FORM_MAN_AT_ARMS").record
	var scribe: Dictionary = registry.get_record("FORM_SCRIBE").record
	var soldier: Dictionary = registry.get_record("RET_SOLDIER_COMPANY").record
	var names: Dictionary = registry.get_record("REC_NAMES_KEPT").record
	_assert(maa.traits[0].modifiers[0].condition_values == ["TAG_SETTLEMENT", "TAG_MARTIAL"], "Old Drill Threshold tag operands")
	_assert(maa.traits[0].modifiers[1].condition_values == ["MARTIAL"], "Old Drill retinue operand")
	_assert(soldier.modifiers[0].condition_values == ["MARTIAL"], "Soldier Company category operand")
	_assert(names.modifiers[0].condition_values == ["WHOLE_SOUL"], "Names Kept Whole-Soul operand")
	_assert(scribe.traits[0].modifiers[0].value_subunits == 2000000 and scribe.traits[0].modifiers[1].value_subunits == 500000, "Scribe modifier values")
	print("M03_TRACE modifiers maa=%s scribe=%s soldier=%s names=%s" % [maa.traits[0].modifiers, scribe.traits[0].modifiers, soldier.modifiers, names.modifiers])

func _assert_milestones_guarantees_resonances(registry: ContentRegistry) -> void:
	_assert(registry.get_record("MS_GLOAMWOOD_REAPING_1000").record.guarantee_ids == ["GUA_SOLDIER_SOULS_12", "GUA_MUSTER_COST_FLOOR"], "1000 guarantees")
	_assert(registry.get_record("MS_GLOAMWOOD_REAPING_2500").record.guarantee_ids == ["GUA_SCRIBE_SOUL_1", "GUA_SCRIBE_AWAKENING_COST_FLOOR"], "2500 guarantees")
	_assert(registry.get_record("MS_GLOAMWOOD_REAPING_5000").record.required_awakened_form_ids == ["FORM_SCRIBE"], "5000 Scribe awakened condition")
	_assert(registry.get_record("MS_THRESHOLD_FIRST_SETTLEMENT").record.prerequisite_ids == [] and registry.get_record("MS_THRESHOLD_FIRST_SETTLEMENT").record.subject_id == "", "first settlement independent empty subject")
	_assert(registry.get_record("GUA_ARCHIVE_WEAVE_COST_FLOOR").record.source_definition_ids == ["HALL_ARCHIVE", "REC_WEAVE_REMEMBERED"], "Archive derived sources")
	_assert(registry.get_record("GUA_MUSTER_COST_FLOOR").record.derived_preview_quantity == 25, "Muster derived preview 25")
	_assert(registry.get_record("GUA_PROVISIONS_ONBOARDING_FLOOR").record.derived_preview_quantity == 36, "Provisions derived preview 36")
	var minor: Dictionary = registry.get_record("RESONANCE_GLOAMWOOD_5000_MINOR").record
	_assert(minor.effects[0].kind == "RECORD_RESONANCE" and minor.effects[0].target_ids == ["RESONANCE_GLOAMWOOD_5000_MINOR"], "minor records itself")
	_assert(minor.effects[1].kind == "UNLOCK_THRESHOLD" and minor.effects[1].target_ids == ["THR_BROKEN_WATCH"], "minor unlocks Broken Watch")
	_assert(minor.effects[2].kind == "ADD_COMMAND_TETHERS" and minor.effects[2].quantity == 1, "minor adds tether")
	var regional: Dictionary = registry.get_record("RESONANCE_REGION_10000").record
	_assert(regional.rewards[0].item_id == "RES_ESSENCE" and regional.rewards[0].quantity == 50, "regional Essence reward")
	_assert(regional.effects[1].kind == "EXPOSE_RECOLLECTIONS" and regional.effects[1].target_ids == ["REC_QUICKER_RECKONING", "REC_NAMES_KEPT", "REC_OPEN_LEDGERS"], "regional recollection exposure")
	print("M03_TRACE milestones_guarantees_resonances minor=%s regional=%s" % [minor.effects, regional.effects])

func _assert_rename_and_override_isolation(catalog: ContentCatalog, registry: ContentRegistry) -> void:
	var scribe_before: String = registry.get_record("FORM_SCRIBE").record.traits[0].display_name
	var rec_before: String = registry.get_record("REC_OPEN_LEDGERS").record.display_name
	var term_before: Dictionary = registry.get_term("TERM_THRESHOLD").term
	catalog.forms[1].traits[0].display_name = "Renamed Ledger"
	catalog.recollections[4].display_name = "Renamed Open Ledgers"
	catalog.terminology.terms[4].singular_display_name = "Passage"
	catalog.terminology.terms[4].plural_display_name = "Passages"
	_assert(registry.get_record("FORM_SCRIBE").record.traits[0].display_name == scribe_before, "Trait rename isolation")
	_assert(registry.get_record("REC_OPEN_LEDGERS").record.display_name == rec_before, "Recollection rename isolation")
	_assert(registry.get_term("TERM_THRESHOLD").term.singular_display_name == term_before.singular_display_name, "TERM_THRESHOLD singular override isolation")
	_assert(registry.get_term("TERM_THRESHOLD").term.plural_display_name == term_before.plural_display_name, "TERM_THRESHOLD plural override isolation")
	var override_catalog: ContentCatalog = load("res://content/prototype_content_catalog.tres").duplicate()
	override_catalog.output_channels = override_catalog.output_channels.duplicate()
	var override_channel: OutputChannelDefinition = override_catalog.output_channels[0].duplicate()
	override_channel.rate.amount_per_period = 2.0
	override_catalog.output_channels[0] = override_channel
	var override_registry := ContentRegistry.build(override_catalog)
	_assert(override_registry.ready, "override catalog ready")
	_assert(override_registry.get_record("CHANNEL_GLOAMWOOD_ESSENCE").record.rate.rate_subunits_per_period == 2000000, "override changes normalized rate")

func _assert_dynamic_guarantee_preview() -> void:
	var catalog: ContentCatalog = load("res://content/prototype_content_catalog.tres").duplicate()
	catalog.recollections = catalog.recollections.duplicate()
	var muster: RecollectionDefinition = catalog.recollections[1].duplicate(true)
	muster.costs[0].quantity = 30
	catalog.recollections[1] = muster
	var registry := ContentRegistry.build(catalog)
	_assert(registry.ready, "dynamic preview catalog ready: %s" % [registry.diagnostics])
	_assert(registry.get_record("GUA_MUSTER_COST_FLOOR").record.derived_preview_quantity == 30, "dynamic Muster preview follows source cost")

func _assert_duplicate_id_failure() -> void:
	var invalid_catalog: ContentCatalog = load("res://content/prototype_content_catalog.tres").duplicate()
	invalid_catalog.items = invalid_catalog.items.duplicate()
	var duplicate_item: ItemDefinition = invalid_catalog.items[0].duplicate()
	duplicate_item.id = "RES_PROVISIONS"
	invalid_catalog.items.append(duplicate_item)
	var invalid := ContentRegistry.build(invalid_catalog)
	_assert(not invalid.ready and not invalid.diagnostics.is_empty(), "duplicate ID failure")
	print("M03_TRACE invalid_duplicate_diagnostics=%d" % invalid.diagnostics.size())

func _assert(condition: bool, label: String) -> void:
	if condition:
		print("M03_TRACE_OK " + label)
	else:
		printerr("M03_TRACE_FAIL " + label)
		quit(1)

func _sorted(values: Array) -> Array:
	var result := values.duplicate()
	result.sort()
	return result

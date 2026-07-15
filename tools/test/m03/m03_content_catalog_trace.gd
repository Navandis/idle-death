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
		_assert(registry.get_term(term_id).ok, "term %s" % term_id)
	print("M03_TRACE revision=%s compatible=%s total=%d terms=%d" % [registry.content_revision, registry.compatible_save_revisions, registry.ids().size(), ContentRegistry.REQUIRED_TERMS.size()])
	print("M03_TRACE groups=%s" % [counts])
	for id in ["RES_ESSENCE", "STORE_RATIONS", "SOUL_CALLING_SOLDIER", "THR_GLOAMWOOD", "THR_BROKEN_WATCH", "FORM_MAN_AT_ARMS", "FORM_SCRIBE"]:
		print("M03_TRACE id=%s record=%s" % [id, registry.get_record(id).record])
	for id in ["CHANNEL_GLOAMWOOD_ESSENCE", "CHANNEL_GLOAMWOOD_SOLDIER_SOULS", "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "CHANNEL_BROKEN_WATCH_ESSENCE", "CHANNEL_BROKEN_WATCH_PROVISIONS", "CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"]:
		var channel: Dictionary = registry.get_record(id).record
		print("M03_TRACE channel=%s period=%d rate=%d" % [id, channel.rate.period_msec, channel.rate.rate_subunits_per_period])
	_assert(registry.get_record("CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS").record.rate.period_msec == 28800000, "eight-hour Scribe channel")
	_assert(registry.get_record("CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS").record.rate.period_msec == 86400000, "twenty-four-hour Man-at-Arms channel")
	var scribe_before: String = registry.get_record("FORM_SCRIBE").record.traits[0].display_name
	var rec_before: String = registry.get_record("REC_OPEN_LEDGERS").record.display_name
	var term_before: String = registry.get_term("TERM_THRESHOLD").term.fallback_text
	catalog.forms[1].traits[0].display_name = "Renamed Ledger"
	catalog.recollections[4].display_name = "Renamed Open Ledgers"
	catalog.terminology.terms[4].fallback_text = "Passage"
	_assert(registry.get_record("FORM_SCRIBE").record.traits[0].display_name == scribe_before, "Trait rename isolation")
	_assert(registry.get_record("REC_OPEN_LEDGERS").record.display_name == rec_before, "Recollection rename isolation")
	_assert(registry.get_term("TERM_THRESHOLD").term.fallback_text == term_before, "TERM_THRESHOLD override isolation")
	var override_catalog: ContentCatalog = load("res://content/prototype_content_catalog.tres").duplicate()
	override_catalog.output_channels = override_catalog.output_channels.duplicate()
	var override_channel: OutputChannelDefinition = override_catalog.output_channels[0].duplicate()
	override_channel.rate.amount_per_period = 2.0
	override_catalog.output_channels[0] = override_channel
	var override_registry := ContentRegistry.build(override_catalog)
	_assert(override_registry.ready, "override catalog ready")
	_assert(override_registry.get_record("CHANNEL_GLOAMWOOD_ESSENCE").record.rate.rate_subunits_per_period == 2000000, "override changes normalized rate")
	var invalid_catalog: ContentCatalog = load("res://content/prototype_content_catalog.tres").duplicate()
	invalid_catalog.items = invalid_catalog.items.duplicate()
	var duplicate_item: ItemDefinition = invalid_catalog.items[0].duplicate()
	duplicate_item.id = "RES_PROVISIONS"
	invalid_catalog.items.append(duplicate_item)
	var invalid := ContentRegistry.build(invalid_catalog)
	_assert(not invalid.ready and not invalid.diagnostics.is_empty(), "duplicate ID failure")
	print("M03_TRACE invalid_duplicate_diagnostics=%d" % invalid.diagnostics.size())
	print("M03_TRACE PASS")
	quit(0)

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

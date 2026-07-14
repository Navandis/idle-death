extends SceneTree

## Headless developer trace for the M03 content catalog.
## It validates the production catalog without a scene tree and prints a compact
## deterministic demonstration for Linux and owner Windows verification.

func _init() -> void:
	var catalog := load("res://content/prototype_content_catalog.tres")
	var registry := ContentRegistry.build(catalog)
	if not registry.ready:
		for diagnostic in registry.diagnostics:
			printerr(diagnostic)
		quit(1)
		return
	print("M03 content revision: %s" % catalog.content_revision)
	print("Compatible revisions: %s" % [catalog.compatible_save_revisions])
	print("Definition count: %d" % registry.ids().size())
	print("Terms: %d" % ContentRegistry.REQUIRED_TERMS.size())
	for id in ["RES_ESSENCE", "CHANNEL_GLOAMWOOD_ESSENCE", "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS", "FORM_MAN_AT_ARMS", "FORM_SCRIBE", "TERM_THRESHOLD"]:
		var result := registry.get_term(id) if id.begins_with("TERM_") else registry.get_record(id)
		print("%s: %s" % [id, result.get("term", result.get("record", {}))])
	var duplicate := ContentDefinition.new()
	duplicate.id = "RES_ESSENCE"
	duplicate.kind = "item"
	duplicate.display_name = "Corrupted Essence"
	var invalid_catalog := catalog.duplicate()
	invalid_catalog.definitions = catalog.definitions.duplicate()
	invalid_catalog.definitions.append(duplicate)
	var invalid := ContentRegistry.build(invalid_catalog)
	print("Invalid duplicate diagnostics: %d" % invalid.diagnostics.size())
	if invalid.ready or invalid.diagnostics.is_empty():
		quit(1)
		return
	quit(0)

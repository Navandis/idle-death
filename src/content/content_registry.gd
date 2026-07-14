class_name ContentRegistry
extends RefCounted

## Validates and normalizes authored content into immutable runtime records.
##
## The registry owns no mutable player state and executes no content-provided
## behavior. Construction is all-or-nothing: any diagnostic prevents readiness and
## leaves lookups empty. Numeric decimals are normalized once through the central
## FixedPoint scale into signed integer subunits, with nearest-subunit rounding;
## the normalized authority intentionally stores no floats.

const CURRENT_REVISION := "prototype-content-r1"
const COMPATIBLE_REVISIONS := ["prototype-content-r1", "prototype-m02"]
const REQUIRED_TERMS := ["TERM_ART", "TERM_CALLING_SOUL", "TERM_COMMAND_TETHER", "TERM_DENIZEN_SOUL", "TERM_ESSENCE", "TERM_FORM", "TERM_FORM_SOUL", "TERM_HALL", "TERM_MASTERY", "TERM_REAPING", "TERM_REAPING_REPORT", "TERM_RECOLLECTION", "TERM_RETINUE", "TERM_SEAL", "TERM_SOULWEAVE", "TERM_STORE", "TERM_THRESHOLD", "TERM_TRAIT", "TERM_WHOLE_SOUL", "TERM_WRIT"]
const REQUIRED_IDS := [
	"RES_ESSENCE", "SOUL_SOLDIER", "SOUL_FORM_MAN_AT_ARMS", "SOUL_FORM_SCRIBE", "RES_PROVISIONS", "RES_RATIONS",
	"FORM_MAN_AT_ARMS", "FORM_SCRIBE", "THR_GLOAMWOOD_HAMLET", "THR_BROKEN_WATCH", "CHANNEL_GLOAMWOOD_ESSENCE", "CHANNEL_GLOAMWOOD_SOLDIER_SOULS", "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "CHANNEL_BROKEN_WATCH_ESSENCE", "CHANNEL_BROKEN_WATCH_PROVISIONS", "CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS",
	"WRIT_EMERGENCY", "WRIT_STANDARD", "RET_SOLDIER_COMPANY", "HALL_ARCHIVE", "HALL_LARDER", "RECIPE_PROVISIONS_TO_RATIONS",
	"REC_FIRST_SEAL_RESONANCE", "REC_DRILL_MEMORY", "REC_SUPPLY_CACHE", "REC_PATROL_ROUTES", "REC_LEDGER_MARGINALIA",
	"MILESTONE_GLOAMWOOD_1000", "MILESTONE_GLOAMWOOD_5000", "MILESTONE_REGIONAL_SOULS_10000", "MILESTONE_SCRIBE_AWAKENED", "MILESTONE_SOLDIER_COMPANY_READY", "MILESTONE_BROKEN_WATCH_CHARTED",
	"GUARANTEE_OPENING_FOUR_SOULS", "GUARANTEE_MAN_AT_ARMS_FORM_SOUL", "GUARANTEE_SCRIBE_FORM_SOUL", "GUARANTEE_SCRIBE_ESSENCE", "GUARANTEE_SOLDIER_COMPANY_SOULS", "GUARANTEE_ONBOARDING_BUFFER",
	"RESONANCE_FIRST_SEAL_MINOR", "RESONANCE_SECOND_SEAL_ESSENCE", "TUT_OPENING", "TUT_FAILED_FOUR_SOULS", "TUT_GLOAMWOOD_DISPATCH", "TUT_MAN_AT_ARMS_AWAKEN", "TUT_EMERGENCY_TO_STANDARD", "TUT_SCRIBE_DISCOVERY", "TUT_SCRIBE_AWAKEN", "TUT_ARCHIVE_RECOLLECTION", "TUT_SOLDIER_COMPANY", "TUT_BROKEN_WATCH", "TUT_SECOND_TETHER", "TUT_PROVISIONS", "TUT_LARDER", "TUT_OFFLINE_REPORT", "CHAR_DEATH", "CHAR_EUSTACE", "CHAR_MAN_AT_ARMS", "DIALOGUE_OPENING_AWAKENING", "DIALOGUE_FOUR_RETURNS_AND_SEALS"]
const METRICS := ["SOULS_RETURNED_RATE", "ESSENCE_YIELD", "MASTERY_RATE", "DISCOVERY_RATE", "FORECAST_UNCERTAINTY", "RETINUE_CONTRIBUTION", "SUPPORT_CONSUMPTION", "SETTLED_OUTPUT", "OUTPUT_CHANNEL_RATE"]
const OPS := ["ADD", "MULTIPLY", "OVERRIDE"]
const SCOPES := ["REAPING_TOTAL", "RETINUE_OWN_CONTRIBUTION", "OUTPUT_CHANNEL", "FORECAST_ONLY"]
const CONDITIONS := ["ALWAYS", "THRESHOLD_HAS_ANY_TAG", "RETINUE_CATEGORY", "OUTPUT_ITEM", "OUTPUT_KIND", "SUPPORT_STATE", "THRESHOLD_LIFECYCLE"]
const EFFECTS := ["GRANT_ITEMS", "TOP_UP_ITEM", "TOP_UP_DERIVED_COST_FLOOR", "UNLOCK_FEATURE", "UNLOCK_THRESHOLD", "ADD_COMMAND_TETHERS", "RECORD_RESONANCE", "TRANSITION_WRIT", "EXPOSE_RECOLLECTIONS", "SET_WORLD_FLAG", "QUEUE_PRESENTATION_EVENT"]

var ready := false
var diagnostics: Array[String] = []
var _records := {}
var _terms := {}

static func build(catalog: ContentCatalog) -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry._build(catalog)
	return registry

static func is_save_revision_compatible(revision: String) -> bool:
	return COMPATIBLE_REVISIONS.has(revision)

func ids() -> Array:
	var keys := _records.keys()
	keys.sort()
	return keys

func get_record(id: String) -> Dictionary:
	if not ready or not _records.has(id):
		return {"ok": false, "code": "CONTENT_ID_NOT_FOUND", "id": id}
	return {"ok": true, "record": _deep_copy(_records[id])}

func get_term(id: String) -> Dictionary:
	if not ready or not _terms.has(id):
		return {"ok": false, "code": "CONTENT_TERM_NOT_FOUND", "id": id}
	return {"ok": true, "term": _deep_copy(_terms[id])}

func _build(catalog: ContentCatalog) -> void:
	if catalog == null:
		diagnostics.append("catalog: missing ContentCatalog")
		return
	_validate_revision(catalog)
	_validate_terms(catalog.terminology)
	var seen := {}
	for definition in catalog.definitions:
		_validate_definition(definition, seen)
	for required_id in REQUIRED_IDS:
		if not seen.has(required_id):
			diagnostics.append("definitions.%s: missing required production definition" % required_id)
	_validate_channel_ownership(seen)
	if diagnostics.is_empty():
		ready = true
		_records = seen

func _validate_revision(catalog: ContentCatalog) -> void:
	if catalog.content_revision != CURRENT_REVISION:
		diagnostics.append("content_revision: expected %s got %s" % [CURRENT_REVISION, catalog.content_revision])
	var revisions := catalog.compatible_save_revisions.duplicate()
	var sorted := revisions.duplicate(); sorted.sort()
	if revisions != sorted:
		diagnostics.append("compatible_save_revisions: must be canonical sorted order")
	var seen := {}
	for revision in revisions:
		if revision == "" or seen.has(revision):
			diagnostics.append("compatible_save_revisions.%s: empty or duplicate revision" % revision)
		seen[revision] = true
	if not revisions.has(catalog.content_revision):
		diagnostics.append("compatible_save_revisions: current revision missing")
	for expected in COMPATIBLE_REVISIONS:
		if not revisions.has(expected):
			diagnostics.append("compatible_save_revisions.%s: missing expected compatible revision" % expected)

func _validate_terms(terminology: CoreTerminologyDefinition) -> void:
	if terminology == null:
		diagnostics.append("terminology: missing CoreTerminologyDefinition")
		return
	for term_id in terminology.terms.keys():
		if not REQUIRED_TERMS.has(term_id):
			diagnostics.append("terminology.%s: unsupported TERM_ entry" % term_id)
		var text := str(terminology.terms[term_id])
		if text.strip_edges() == "":
			diagnostics.append("terminology.%s: fallback text is empty" % term_id)
		_terms[term_id] = {"id": term_id, "fallback_text": text}
	for term_id in REQUIRED_TERMS:
		if not terminology.terms.has(term_id):
			diagnostics.append("terminology.%s: missing required term" % term_id)

func _validate_definition(definition: ContentDefinition, seen: Dictionary) -> void:
	if definition == null:
		diagnostics.append("definitions: null definition reference")
		return
	if not _valid_id(definition.id):
		diagnostics.append("%s.id: invalid uppercase canonical ID" % definition.resource_path)
	if seen.has(definition.id):
		diagnostics.append("%s.id: duplicate global ID %s" % [definition.resource_path, definition.id])
	if definition.display_name.strip_edges() == "":
		diagnostics.append("%s.display_name: empty display name for %s" % [definition.resource_path, definition.id])
	if definition.id == "RES_CORRUPTED_ESSENCE" or definition.id.find("CORRUPTED_ESSENCE") >= 0 or definition.display_name == "Corrupted Essence":
		diagnostics.append("%s: deprecated Essence identity or display term" % definition.id)
	var normalized: Dictionary = _normalize_value(definition.data, definition.id)
	_validate_grammar(normalized, definition.id)
	var record := {"id": definition.id, "kind": definition.kind, "display_name": definition.display_name, "description": definition.description, "localization_key": definition.localization_key, "data": normalized}
	seen[definition.id] = record

func _normalize_value(value, path: String):
	if typeof(value) == TYPE_DICTIONARY:
		var result := {}
		for key in value.keys():
			if str(key).find("script_path") >= 0 or str(key).find("callable") >= 0 or str(key).find("expression") >= 0:
				diagnostics.append("%s.%s: executable content fields are forbidden" % [path, key])
			result[key] = _normalize_value(value[key], "%s.%s" % [path, key])
		return result
	if typeof(value) == TYPE_ARRAY:
		var result := []
		for index in range(value.size()):
			result.append(_normalize_value(value[index], "%s[%d]" % [path, index]))
		return result
	if typeof(value) == TYPE_FLOAT:
		if is_nan(value) or is_inf(value) or value < 0.0 or value > float(FixedPoint.INT64_MAX) / float(FixedPoint.SCALE):
			diagnostics.append("%s: invalid authored decimal" % path)
			return 0
		return int(value * float(FixedPoint.SCALE) + 0.5)
	return value

func _validate_grammar(data: Dictionary, id: String) -> void:
	for modifier in data.get("modifiers", []):
		if not METRICS.has(modifier.get("metric", "")):
			diagnostics.append("%s.modifiers.metric: unsupported metric" % id)
		if not OPS.has(modifier.get("operation", "")):
			diagnostics.append("%s.modifiers.operation: unsupported operation" % id)
		if not SCOPES.has(modifier.get("scope", "")):
			diagnostics.append("%s.modifiers.scope: unsupported scope" % id)
		if not CONDITIONS.has(modifier.get("condition", "ALWAYS")):
			diagnostics.append("%s.modifiers.condition: unsupported condition" % id)
	for effect in data.get("effects", []):
		if not EFFECTS.has(effect.get("kind", "")):
			diagnostics.append("%s.effects.kind: unsupported effect kind" % id)
		if not effect.has("id"):
			diagnostics.append("%s.effects.id: missing effect identity" % id)
	if data.has("period_msec") and int(data.period_msec) <= 0:
		diagnostics.append("%s.period_msec: period must be positive" % id)
	if data.get("requires_progress_display", false) and (data.get("output_kind", "") != "WHOLE_ITEM" or int(data.get("rate_per_period", 0)) <= 0):
		diagnostics.append("%s.progress_display: requires positive whole-item channel" % id)
	if id == "RET_SOLDIER_COMPANY" and int(data.get("required_soldier_souls", -1)) != 12:
		diagnostics.append("RET_SOLDIER_COMPANY.required_soldier_souls: expected exactly 12")

func _validate_channel_ownership(records: Dictionary) -> void:
	for id in records.keys():
		var data: Dictionary = records[id].data
		if id.begins_with("CHANNEL_"):
			var threshold_id: String = data.get("source_threshold_id", "")
			var item_id: String = data.get("output_item_id", "")
			if not records.has(threshold_id) or records[threshold_id].kind != "threshold":
				diagnostics.append("%s.source_threshold_id: missing Threshold %s" % [id, threshold_id])
			if not records.has(item_id) or records[item_id].kind != "item":
				diagnostics.append("%s.output_item_id: missing item %s" % [id, item_id])
			if int(data.get("period_msec", 0)) <= 0:
				diagnostics.append("%s.period_msec: missing positive period" % id)
			if records.has(threshold_id) and not records[threshold_id].data.get("channel_ids", []).has(id):
				diagnostics.append("%s: channel not listed by owning Threshold %s" % [id, threshold_id])

func _valid_id(id: String) -> bool:
	if id == "":
		return false
	for i in id.length():
		var c := id.unicode_at(i)
		var ok := (c >= 65 and c <= 90) or (c >= 48 and c <= 57) or c == 95
		if not ok:
			return false
	return id.find("_") > 0

static func _deep_copy(value):
	return var_to_str(value) if false else str_to_var(var_to_str(value))

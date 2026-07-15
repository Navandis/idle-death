class_name ContentRegistry
extends RefCounted

## Builds immutable normalized runtime content from typed M03 authored Resources.
##
## The registry validates the exact approved prototype contract and never scans
## directories, keys mechanics from display names, or executes content-provided
## behavior. Construction is all-or-nothing: diagnostics are available on failure,
## but records are queryable only when `ready` is true.

const CURRENT_REVISION := "prototype-content-r1"
const COMPATIBLE_REVISIONS := ["prototype-content-r1", "prototype-m02"]
const REQUIRED_TERMS := ["TERM_ART", "TERM_CALLING_SOUL", "TERM_COMMAND_TETHER", "TERM_DENIZEN_SOUL", "TERM_ESSENCE", "TERM_FORM", "TERM_FORM_SOUL", "TERM_HALL", "TERM_MASTERY", "TERM_REAPING", "TERM_REAPING_REPORT", "TERM_RECOLLECTION", "TERM_RETINUE", "TERM_SEAL", "TERM_SOULWEAVE", "TERM_STORE", "TERM_THRESHOLD", "TERM_TRAIT", "TERM_WHOLE_SOUL", "TERM_WRIT"]
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
const REJECTED_IDS := ["SOUL_SOLDIER", "RES_RATIONS", "THR_GLOAMWOOD_HAMLET", "WRIT_EMERGENCY", "RECIPE_PROVISIONS_TO_RATIONS", "REC_FIRST_SEAL_RESONANCE", "REC_DRILL_MEMORY", "REC_SUPPLY_CACHE", "REC_PATROL_ROUTES", "REC_LEDGER_MARGINALIA", "GUARANTEE_OPENING_FOUR_SOULS", "RESONANCE_FIRST_SEAL_MINOR", "RESONANCE_SECOND_SEAL_ESSENCE", "TUT_OPENING"]
const METRICS := ["SOULS_RETURNED_RATE", "ESSENCE_YIELD", "MASTERY_RATE", "DISCOVERY_RATE", "FORECAST_UNCERTAINTY", "RETINUE_CONTRIBUTION", "SUPPORT_CONSUMPTION", "SETTLED_OUTPUT", "OUTPUT_CHANNEL_RATE"]
const OPS := ["ADD", "MULTIPLY", "OVERRIDE"]
const SCOPES := ["REAPING_TOTAL", "RETINUE_OWN_CONTRIBUTION", "OUTPUT_CHANNEL", "FORECAST_ONLY"]
const CONDITIONS := ["ALWAYS", "THRESHOLD_HAS_ANY_TAG", "RETINUE_CATEGORY", "OUTPUT_ITEM", "OUTPUT_KIND", "SUPPORT_STATE", "THRESHOLD_LIFECYCLE"]
const EFFECTS := ["GRANT_ITEMS", "TOP_UP_ITEM", "TOP_UP_DERIVED_COST_FLOOR", "UNLOCK_FEATURE", "UNLOCK_THRESHOLD", "ADD_COMMAND_TETHERS", "RECORD_RESONANCE", "TRANSITION_WRIT", "EXPOSE_RECOLLECTIONS", "SET_WORLD_FLAG", "QUEUE_PRESENTATION_EVENT"]
const DISCOVERY_STATES := ["UNKNOWN", "IDENTIFIED", "CHARTED"]
const FREQUENCY_TIERS := ["NONE", "COMMON", "UNCOMMON"]
const APPROVED_TAGS := ["TAG_FOREST", "TAG_SETTLEMENT", "TAG_ROAD", "TAG_MARTIAL"]
const RETINUE_CATEGORIES := ["MARTIAL", "LOGISTICS", "EXTRACTION"]
const OUTPUT_KIND_CONDITIONS := ["WHOLE_SOUL"]
const SUPPORT_STATES := ["FULL", "REDUCED"]
const THRESHOLD_LIFECYCLES := ["STANDING", "SETTLED"]
const DERIVED_POLICIES := ["", "SUM_REMAINING_COSTS", "LARDER_RESTORE_PLUS_FIRST_BATCH_AND_BUFFER"]
const GROUP_SPECS := {
	"items": {"ids": ["RES_ESSENCE", "RES_PROVISIONS", "STORE_RATIONS", "SOUL_CALLING_SOLDIER", "SOUL_FORM_SCRIBE", "SOUL_FORM_MAN_AT_ARMS"], "type": "item"},
	"forms": {"ids": ["FORM_MAN_AT_ARMS", "FORM_SCRIBE"], "type": "form"},
	"thresholds": {"ids": ["THR_GLOAMWOOD", "THR_BROKEN_WATCH"], "type": "threshold"},
	"output_channels": {"ids": ["CHANNEL_GLOAMWOOD_ESSENCE", "CHANNEL_GLOAMWOOD_SOLDIER_SOULS", "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "CHANNEL_BROKEN_WATCH_ESSENCE", "CHANNEL_BROKEN_WATCH_PROVISIONS", "CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"], "type": "channel"},
	"writs": {"ids": ["WRIT_EMERGENCY_FIRST_RETURN", "WRIT_STANDARD"], "type": "writ"},
	"retinues": {"ids": ["RET_SOLDIER_COMPANY"], "type": "retinue"},
	"halls": {"ids": ["HALL_ARCHIVE", "HALL_LARDER"], "type": "hall"},
	"recipes": {"ids": ["RECIPE_LARDER_PROVISIONS_TO_RATIONS"], "type": "recipe"},
	"recollections": {"ids": ["REC_WEAVE_REMEMBERED", "REC_MUSTER_REMEMBERED", "REC_QUICKER_RECKONING", "REC_NAMES_KEPT", "REC_OPEN_LEDGERS"], "type": "recollection"},
	"milestones": {"ids": ["MS_GLOAMWOOD_REAPING_1000", "MS_GLOAMWOOD_REAPING_2500", "MS_GLOAMWOOD_REAPING_5000", "MS_REGION_REAPING_10000", "MS_REGION_REAPING_25000", "MS_THRESHOLD_FIRST_SETTLEMENT"], "type": "milestone"},
	"guarantees": {"ids": ["GUA_ARCHIVE_WEAVE_COST_FLOOR", "GUA_SOLDIER_SOULS_12", "GUA_MUSTER_COST_FLOOR", "GUA_SCRIBE_SOUL_1", "GUA_SCRIBE_AWAKENING_COST_FLOOR", "GUA_PROVISIONS_ONBOARDING_FLOOR"], "type": "guarantee"},
	"resonances": {"ids": ["RESONANCE_GLOAMWOOD_5000_MINOR", "RESONANCE_REGION_10000"], "type": "resonance"},
	"tutorial_steps": {"ids": ["TUT_00_BOOT", "TUT_01_WINDOW", "TUT_02_DIRECT_REAP", "TUT_03_SOULS_RETURN", "TUT_04_FIRST_DISPATCH", "TUT_05_ARCHIVE", "TUT_06_SOULWEAVE", "TUT_07_RETINUE", "TUT_08_SCRIBE", "TUT_09_SECOND_THRESHOLD", "TUT_10_DISCOVERY", "TUT_11_LARDER", "TUT_12_SEAL_CHOICE", "TUT_13_COMPLETE"], "type": "tutorial"},
	"narrative_identities": {"ids": ["CHAR_DEATH", "CHAR_EUSTACE", "CHAR_MAN_AT_ARMS", "DIALOGUE_OPENING_AWAKENING", "DIALOGUE_FOUR_RETURNS_AND_SEALS"], "type": "narrative"},
}

var ready := false
var diagnostics: Array[String] = []
var content_revision := ""
var compatible_save_revisions: Array[String] = []
var _records := {}
var _terms := {}
var _group_counts := {}

static func build(catalog: ContentCatalog) -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry._build(catalog)
	return registry

func is_save_revision_compatible(revision: String) -> bool:
	return ready and compatible_save_revisions.has(revision)

func ids() -> Array:
	var keys := _records.keys()
	keys.sort()
	return keys

func group_counts() -> Dictionary:
	return _deep_copy(_group_counts)

func get_record(id: String) -> Dictionary:
	if not ready or not _records.has(id):
		return {"ok": false, "code": "CONTENT_ID_NOT_FOUND", "id": id}
	return {"ok": true, "record": _deep_copy(_records[id])}

func get_term(id: String) -> Dictionary:
	if not ready or not _terms.has(id):
		return {"ok": false, "code": "CONTENT_TERM_NOT_FOUND", "id": id}
	return {"ok": true, "term": _deep_copy(_terms[id])}

func channel_shows_acquisition_progress(channel_id: String, discovery_state: String) -> bool:
	if not ready or not _records.has(channel_id):
		return false
	var channel: Dictionary = _records[channel_id]
	return channel.show_acquisition_progress and discovery_state != "UNKNOWN"

func _build(catalog: ContentCatalog) -> void:
	if catalog == null:
		_add_error("<catalog>", "catalog", "ContentCatalog", "missing catalog")
		return
	content_revision = catalog.content_revision
	compatible_save_revisions = catalog.compatible_save_revisions.duplicate()
	_validate_revision(catalog)
	_validate_terms(catalog.terminology)
	var seen := {}
	_collect_group("items", catalog.items, seen)
	_collect_group("forms", catalog.forms, seen)
	_collect_group("thresholds", catalog.thresholds, seen)
	_collect_group("output_channels", catalog.output_channels, seen)
	_collect_group("writs", catalog.writs, seen)
	_collect_group("retinues", catalog.retinues, seen)
	_collect_group("halls", catalog.halls, seen)
	_collect_group("recipes", catalog.recipes, seen)
	_collect_group("recollections", catalog.recollections, seen)
	_collect_group("milestones", catalog.milestones, seen)
	_collect_group("guarantees", catalog.guarantees, seen)
	_collect_group("resonances", catalog.resonances, seen)
	_collect_group("tutorial_steps", catalog.tutorial_steps, seen)
	_collect_group("narrative_identities", catalog.narrative_identities, seen)
	_validate_exact_ids(seen)
	_validate_cross_references(seen)
	if diagnostics.is_empty():
		ready = true
		_records = seen

func _validate_revision(catalog: ContentCatalog) -> void:
	if catalog.content_revision != CURRENT_REVISION:
		_add_error(catalog.resource_path, "content_revision", CURRENT_REVISION, catalog.content_revision)
	var sorted := catalog.compatible_save_revisions.duplicate(); sorted.sort()
	if catalog.compatible_save_revisions != sorted:
		_add_error(catalog.resource_path, "compatible_save_revisions", "canonical sorted list", str(catalog.compatible_save_revisions))
	var seen := {}
	for revision in catalog.compatible_save_revisions:
		if revision == "" or seen.has(revision):
			_add_error(catalog.resource_path, "compatible_save_revisions", "non-empty duplicate-free revisions", revision)
		seen[revision] = true
	if catalog.compatible_save_revisions != COMPATIBLE_REVISIONS:
		_add_error(catalog.resource_path, "compatible_save_revisions", str(COMPATIBLE_REVISIONS), str(catalog.compatible_save_revisions))

func _validate_terms(terminology: CoreTerminologyDefinition) -> void:
	if terminology == null:
		_add_error("<catalog>", "terminology", "CoreTerminologyDefinition", "missing")
		return
	var seen := {}
	for term in terminology.terms:
		if term == null:
			_add_error(terminology.resource_path, "terms", "TermDefinition", "null")
			continue
		if seen.has(term.id):
			_add_error(terminology.resource_path, "terms.%s" % term.id, "unique TERM id", "duplicate")
		seen[term.id] = true
		if not REQUIRED_TERMS.has(term.id):
			_add_error(terminology.resource_path, "terms.%s" % term.id, "approved TERM id", term.id)
		if term.singular_display_name.strip_edges() == "":
			_add_error(terminology.resource_path, "terms.%s.singular_display_name" % term.id, "non-empty", "empty")
		if term.plural_display_name.strip_edges() == "":
			_add_error(terminology.resource_path, "terms.%s.plural_display_name" % term.id, "non-empty", "empty")
		_terms[term.id] = {
			"id": term.id,
			"singular_display_name": term.singular_display_name,
			"plural_display_name": term.plural_display_name,
			"singular_localization_key": term.singular_localization_key,
			"plural_localization_key": term.plural_localization_key,
			"notes": term.notes,
		}
	for required in REQUIRED_TERMS:
		if not seen.has(required):
			_add_error(terminology.resource_path, "terms", "contains %s" % required, "missing")

func _collect_group(group_name: String, definitions: Array, seen: Dictionary) -> void:
	var spec: Dictionary = GROUP_SPECS[group_name]
	_group_counts[group_name] = definitions.size()
	for definition in definitions:
		if definition == null:
			_add_error(group_name, "definition", "typed Resource", "null")
			continue
		_validate_common(definition, group_name, spec.ids)
		if seen.has(definition.id):
			_add_error(definition.resource_path, "id", "globally unique", "duplicate %s" % definition.id)
		seen[definition.id] = _normalize_definition(group_name, definition, spec.type)

func _validate_common(definition: ContentDefinitionBase, group_name: String, allowed_ids: Array) -> void:
	if not _valid_id(definition.id):
		_add_error(definition.resource_path, "id", "uppercase canonical ID", definition.id)
	if not allowed_ids.has(definition.id):
		_add_error(definition.resource_path, "id", "ID in %s approved group" % group_name, definition.id)
	if definition.display_name.strip_edges() == "":
		_add_error(definition.resource_path, "display_name", "non-empty fallback name", "empty")
	if definition.id.find("CORRUPTED_ESSENCE") >= 0 or definition.display_name == "Corrupted Essence":
		_add_error(definition.resource_path, "Essence", "Essence-only identity/display text", definition.id)

func _normalize_definition(group_name: String, definition: ContentDefinitionBase, type_name: String) -> Dictionary:
	var record := _base_record(definition, type_name, group_name)
	match group_name:
		"items": _normalize_item(record, definition)
		"forms": _normalize_form(record, definition)
		"thresholds": _normalize_threshold(record, definition)
		"output_channels": _normalize_channel(record, definition)
		"writs": _normalize_writ(record, definition)
		"retinues": _normalize_retinue(record, definition)
		"halls": _normalize_hall(record, definition)
		"recipes": _normalize_recipe(record, definition)
		"recollections": _normalize_recollection(record, definition)
		"milestones": _normalize_milestone(record, definition)
		"guarantees": _normalize_guarantee(record, definition)
		"resonances": _normalize_resonance(record, definition)
		"tutorial_steps": _normalize_tutorial(record, definition)
		"narrative_identities": _normalize_narrative(record, definition)
	return record

func _base_record(definition: ContentDefinitionBase, type_name: String, group_name: String) -> Dictionary:
	return {"id": definition.id, "type": type_name, "group": group_name, "display_name": definition.display_name, "description": definition.description, "localization_key": definition.localization_key, "enabled": definition.enabled, "source_path": definition.resource_path}

func _normalize_item(record: Dictionary, definition: ItemDefinition) -> void:
	record["item_kind"] = definition.item_kind
	record["whole_units_only"] = definition.whole_units_only

func _normalize_form(record: Dictionary, definition: FormDefinition) -> void:
	record["base_returned_souls_rate"] = _normalize_rate(definition.base_returned_souls_rate, definition, "base_returned_souls_rate")
	record["active_mastery_rate"] = _normalize_rate(definition.active_mastery_rate, definition, "active_mastery_rate")
	record["cycle_duration_msec"] = definition.cycle_duration_msec
	record["slot_affinities"] = definition.slot_affinities.duplicate()
	var traits := []
	for trait_definition in definition.traits:
		traits.append(_normalize_trait(trait_definition, definition))
	record["traits"] = traits
	record["awakening_costs"] = _normalize_amounts(definition.awakening_costs, definition, "awakening_costs")

func _normalize_threshold(record: Dictionary, definition: ThresholdDefinition) -> void:
	record["tags"] = definition.tags.duplicate()
	record["standing_backlog"] = definition.standing_backlog
	record["settled_multiplier_subunits"] = _normalize_decimal(definition.settled_multiplier, definition, "settled_multiplier")
	record["channel_ids"] = definition.channel_ids.duplicate()
	record["discovery_state"] = definition.discovery_state

func _normalize_channel(record: Dictionary, definition: OutputChannelDefinition) -> void:
	record["source_threshold_id"] = definition.source_threshold_id
	record["output_item_id"] = definition.output_item_id
	record["output_kind"] = definition.output_kind
	record["rate"] = _normalize_rate(definition.rate, definition, "rate")
	record["settled_multiplier_subunits"] = _normalize_decimal(definition.settled_multiplier, definition, "settled_multiplier")
	record["progression_required"] = definition.progression_required
	record["initial_discovery_state"] = definition.initial_discovery_state
	record["frequency_tier"] = definition.frequency_tier
	record["identified_frequency_label"] = definition.identified_frequency_label
	record["frequency_localization_key"] = definition.frequency_localization_key
	record["show_acquisition_progress"] = definition.show_acquisition_progress
	record["identification_cycles_base"] = definition.identification_cycles_base
	record["identification_cycles_scribe"] = definition.identification_cycles_scribe
	record["charting_cycles_base"] = definition.charting_cycles_base

func _normalize_writ(record: Dictionary, definition: WritDefinition) -> void:
	record["transition_milestone_id"] = definition.transition_milestone_id
	record["transition_to_writ_id"] = definition.transition_to_writ_id
	record["effects"] = _normalize_effects(definition.effects, definition, "effects")

func _normalize_retinue(record: Dictionary, definition: RetinueDefinition) -> void:
	record["required_items"] = _normalize_amounts(definition.required_items, definition, "required_items")
	record["support_item_id"] = definition.support_item_id
	record["support_period_msec"] = definition.support_period_msec
	record["reduced_support_floor_subunits"] = _normalize_decimal(definition.reduced_support_floor, definition, "reduced_support_floor")
	record["slot_categories"] = definition.slot_categories.duplicate()
	record["modifiers"] = _normalize_modifiers(definition.modifiers, definition, "modifiers")

func _normalize_hall(record: Dictionary, definition: HallDefinition) -> void:
	record["restoration_costs"] = _normalize_amounts(definition.restoration_costs, definition, "restoration_costs")
	record["unlocks_feature_id"] = definition.unlocks_feature_id

func _normalize_recipe(record: Dictionary, definition: RecipeDefinition) -> void:
	record["hall_id"] = definition.hall_id
	record["input"] = _normalize_amount(definition.input, definition, "input")
	record["output"] = _normalize_amount(definition.output, definition, "output")
	record["duration_msec"] = definition.duration_msec
	record["default_target_quantity"] = definition.default_target_quantity

func _normalize_recollection(record: Dictionary, definition: RecollectionDefinition) -> void:
	record["costs"] = _normalize_amounts(definition.costs, definition, "costs")
	record["prerequisite_ids"] = definition.prerequisite_ids.duplicate()
	record["repeatable"] = definition.repeatable
	record["effects"] = _normalize_effects(definition.effects, definition, "effects")
	record["modifiers"] = _normalize_modifiers(definition.modifiers, definition, "modifiers")

func _normalize_milestone(record: Dictionary, definition: MilestoneDefinition) -> void:
	record["counter_kind"] = definition.counter_kind
	record["subject_id"] = definition.subject_id
	record["target_count"] = definition.target_count
	record["prerequisite_ids"] = definition.prerequisite_ids.duplicate()
	record["required_awakened_form_ids"] = definition.required_awakened_form_ids.duplicate()
	record["guarantee_ids"] = definition.guarantee_ids.duplicate()
	record["resonance_id"] = definition.resonance_id
	record["effects"] = _normalize_effects(definition.effects, definition, "effects")

func _normalize_guarantee(record: Dictionary, definition: GuaranteeDefinition) -> void:
	record["policy"] = definition.policy
	record["item_id"] = definition.item_id
	record["minimum_amount"] = definition.minimum_amount
	record["source_definition_ids"] = definition.source_definition_ids.duplicate()
	record["derived_policy_id"] = definition.derived_policy_id
	record["buffer_multiplier_subunits"] = _normalize_decimal(definition.buffer_multiplier, definition, "buffer_multiplier")
	record["derived_preview_quantity"] = definition.minimum_amount

func _normalize_resonance(record: Dictionary, definition: ResonanceDefinition) -> void:
	record["trigger_milestone_id"] = definition.trigger_milestone_id
	record["rewards"] = _normalize_amounts(definition.rewards, definition, "rewards")
	record["effects"] = _normalize_effects(definition.effects, definition, "effects")

func _normalize_tutorial(record: Dictionary, definition: TutorialStepDefinition) -> void:
	record["sequence_index"] = definition.sequence_index
	record["presentation_event_id"] = definition.presentation_event_id
	record["presentation_only"] = definition.presentation_only

func _normalize_narrative(record: Dictionary, definition: NarrativeIdentityDefinition) -> void:
	record["narrative_kind"] = definition.narrative_kind
	record["presentation_only"] = definition.presentation_only

func _normalize_trait(trait_definition: TraitDefinition, owner: Resource) -> Dictionary:
	if trait_definition == null:
		_add_error(owner.resource_path, "traits", "TraitDefinition", "null")
		return {}
	if not ["TRAIT_OLD_DRILL", "TRAIT_UNCLOSED_LEDGER"].has(trait_definition.id):
		_add_error(owner.resource_path, "traits.id", "approved inline Trait ID", trait_definition.id)
	if trait_definition.display_name.strip_edges() == "":
		_add_error(owner.resource_path, "traits.%s.display_name" % trait_definition.id, "non-empty", "empty")
	return {"id": trait_definition.id, "display_name": trait_definition.display_name, "description": trait_definition.description, "localization_key": trait_definition.localization_key, "modifiers": _normalize_modifiers(trait_definition.modifiers, owner, "traits.%s.modifiers" % trait_definition.id)}

func _normalize_modifiers(modifiers: Array, owner: Resource, field: String) -> Array:
	var result := []
	for modifier in modifiers:
		if modifier == null:
			_add_error(owner.resource_path, field, "ModifierDefinition", "null")
			continue
		if not METRICS.has(modifier.metric): _add_error(owner.resource_path, field + ".metric", "approved metric", modifier.metric)
		if not OPS.has(modifier.operation): _add_error(owner.resource_path, field + ".operation", "approved operation", modifier.operation)
		if not SCOPES.has(modifier.scope): _add_error(owner.resource_path, field + ".scope", "approved scope", modifier.scope)
		if not CONDITIONS.has(modifier.condition): _add_error(owner.resource_path, field + ".condition", "approved condition", modifier.condition)
		_validate_modifier_operands(modifier, owner, field)
		result.append({"metric": modifier.metric, "operation": modifier.operation, "scope": modifier.scope, "condition": modifier.condition, "condition_values": modifier.condition_values.duplicate(), "value_subunits": _normalize_decimal(modifier.value, owner, field + ".value")})
	return result

func _normalize_effects(effects: Array, owner: Resource, field: String) -> Array:
	var result := []
	for effect in effects:
		if effect == null:
			_add_error(owner.resource_path, field, "ProgressionEffectDefinition", "null")
			continue
		if effect.id.strip_edges() == "": _add_error(owner.resource_path, field + ".id", "non-empty effect id", "empty")
		if not EFFECTS.has(effect.kind): _add_error(owner.resource_path, field + ".kind", "approved effect kind", effect.kind)
		result.append({"id": effect.id, "kind": effect.kind, "item_amounts": _normalize_amounts(effect.item_amounts, owner, field + ".item_amounts"), "target_ids": effect.target_ids.duplicate(), "quantity": effect.quantity})
	return result

func _normalize_amounts(amounts: Array, owner: Resource, field: String) -> Array:
	var result := []
	for index in range(amounts.size()):
		result.append(_normalize_amount(amounts[index], owner, "%s[%d]" % [field, index]))
	return result

func _normalize_amount(amount: ItemAmountDefinition, owner: Resource, field: String) -> Dictionary:
	if amount == null:
		_add_error(owner.resource_path, field, "ItemAmountDefinition", "null")
		return {"item_id": "", "quantity": 0}
	if amount.quantity <= 0:
		_add_error(owner.resource_path, field + ".quantity", "positive integer", str(amount.quantity))
	return {"item_id": amount.item_id, "quantity": amount.quantity}

func _normalize_rate(rate: RateDefinition, owner: Resource, field: String) -> Dictionary:
	if rate == null:
		_add_error(owner.resource_path, field, "RateDefinition", "null")
		return {"rate_subunits_per_period": 0, "period_msec": 0}
	if rate.period_msec <= 0:
		_add_error(owner.resource_path, field + ".period_msec", "positive integer milliseconds", str(rate.period_msec))
	return {"rate_subunits_per_period": _normalize_decimal(rate.amount_per_period, owner, field + ".amount_per_period"), "period_msec": rate.period_msec}

func _validate_modifier_operands(modifier: ModifierDefinition, owner: Resource, field: String) -> void:
	match modifier.condition:
		"ALWAYS":
			if not modifier.condition_values.is_empty(): _add_error(owner.resource_path, field + ".condition_values", "empty for ALWAYS", str(modifier.condition_values))
		"THRESHOLD_HAS_ANY_TAG":
			_validate_string_operands(modifier.condition_values, APPROVED_TAGS, owner.resource_path, field + ".condition_values")
		"RETINUE_CATEGORY":
			_validate_string_operands(modifier.condition_values, RETINUE_CATEGORIES, owner.resource_path, field + ".condition_values")
		"OUTPUT_KIND":
			_validate_string_operands(modifier.condition_values, OUTPUT_KIND_CONDITIONS, owner.resource_path, field + ".condition_values")
		"SUPPORT_STATE":
			_validate_string_operands(modifier.condition_values, SUPPORT_STATES, owner.resource_path, field + ".condition_values")
		"THRESHOLD_LIFECYCLE":
			_validate_string_operands(modifier.condition_values, THRESHOLD_LIFECYCLES, owner.resource_path, field + ".condition_values")
		"OUTPUT_ITEM":
			if modifier.condition_values.is_empty(): _add_error(owner.resource_path, field + ".condition_values", "one or more item IDs", "empty")

func _validate_string_operands(values: Array[String], allowed: Array, source: String, field: String) -> void:
	if values.is_empty():
		_add_error(source, field, "one or more operands", "empty")
	for value in values:
		if not allowed.has(value):
			_add_error(source, field, "one of %s" % str(allowed), value)

func _normalize_decimal(value: float, owner: Resource, field: String) -> int:
	if is_nan(value) or is_inf(value) or value < 0.0 or value > float(FixedPoint.INT64_MAX) / float(FixedPoint.SCALE):
		_add_error(owner.resource_path, field, "finite non-negative fixed-point decimal", str(value))
		return 0
	return int(value * float(FixedPoint.SCALE) + 0.5)

func _validate_exact_ids(records: Dictionary) -> void:
	var actual := records.keys(); actual.sort()
	var expected := APPROVED_IDS.duplicate(); expected.sort()
	if actual != expected:
		_add_error("<catalog>", "approved_ids", str(expected), str(actual))
	for rejected in REJECTED_IDS:
		if records.has(rejected):
			_add_error("<catalog>", "removed_id", "absent", rejected)

func _validate_cross_references(records: Dictionary) -> void:
	for id in records.keys():
		var record: Dictionary = records[id]
		match record.type:
			"form": _validate_form_record(record, records)
			"threshold": _validate_threshold_record(record, records)
			"channel": _validate_channel_record(record, records)
			"writ": _validate_writ_record(record, records)
			"retinue": _validate_retinue_record(record, records)
			"hall": _validate_hall_record(record, records)
			"recipe": _validate_recipe_record(record, records)
			"recollection": _validate_recollection_record(record, records)
			"milestone": _validate_milestone_record(record, records)
			"guarantee": _validate_guarantee_record(record, records)
			"resonance": _validate_resonance_record(record, records)
			"tutorial":
				if not record.presentation_only: _add_error(record.source_path, "presentation_only", "true", "false")
			"narrative":
				if not record.presentation_only: _add_error(record.source_path, "presentation_only", "true", "false")

func _validate_form_record(record: Dictionary, records: Dictionary) -> void:
	if record.cycle_duration_msec != 60000: _add_error(record.source_path, "cycle_duration_msec", "60000", str(record.cycle_duration_msec))
	for cost in record.awakening_costs: _expect_id(records, cost.item_id, "item", record.source_path, "awakening_costs.item_id")

func _validate_threshold_record(record: Dictionary, records: Dictionary) -> void:
	if record.standing_backlog <= 0: _add_error(record.source_path, "standing_backlog", "positive", str(record.standing_backlog))
	for channel_id in record.channel_ids: _expect_id(records, channel_id, "channel", record.source_path, "channel_ids")
	for tag in record.tags:
		if not APPROVED_TAGS.has(tag): _add_error(record.source_path, "tags", "approved TAG value", tag)
	if record.id == "THR_GLOAMWOOD":
		if record.display_name != "Gloamwood Hamlet": _add_error(record.source_path, "display_name", "Gloamwood Hamlet", record.display_name)
		if record.standing_backlog != 1000000: _add_error(record.source_path, "standing_backlog", "1000000", str(record.standing_backlog))
		if record.tags != ["TAG_FOREST", "TAG_SETTLEMENT"]: _add_error(record.source_path, "tags", "[TAG_FOREST, TAG_SETTLEMENT]", str(record.tags))
	if record.id == "THR_BROKEN_WATCH":
		if record.standing_backlog != 250000: _add_error(record.source_path, "standing_backlog", "250000", str(record.standing_backlog))
		if record.tags != ["TAG_ROAD", "TAG_SETTLEMENT", "TAG_MARTIAL"]: _add_error(record.source_path, "tags", "[TAG_ROAD, TAG_SETTLEMENT, TAG_MARTIAL]", str(record.tags))

func _validate_channel_record(record: Dictionary, records: Dictionary) -> void:
	_expect_id(records, record.source_threshold_id, "threshold", record.source_path, "source_threshold_id")
	_expect_id(records, record.output_item_id, "item", record.source_path, "output_item_id")
	if record.rate.period_msec <= 0 or record.rate.rate_subunits_per_period <= 0: _add_error(record.source_path, "rate", "positive rate and period", str(record.rate))
	if not DISCOVERY_STATES.has(record.initial_discovery_state): _add_error(record.source_path, "initial_discovery_state", "approved discovery state", record.initial_discovery_state)
	if not FREQUENCY_TIERS.has(record.frequency_tier): _add_error(record.source_path, "frequency_tier", "approved frequency tier", record.frequency_tier)
	if record.frequency_tier != "NONE" and record.identified_frequency_label.strip_edges() == "":
		_add_error(record.source_path, "identified_frequency_label", "non-empty for non-NONE frequency", "empty")
	if record.show_acquisition_progress and record.output_kind != "WHOLE_ITEM":
		_add_error(record.source_path, "show_acquisition_progress", "whole item channel", record.output_kind)
	if records.has(record.source_threshold_id) and not records[record.source_threshold_id].channel_ids.has(record.id):
		_add_error(record.source_path, "source_threshold_id", "owning threshold lists channel", record.source_threshold_id)
	_validate_channel_contract(record)

func _validate_channel_contract(record: Dictionary) -> void:
	var expected := {
		"CHANNEL_GLOAMWOOD_ESSENCE": ["CHARTED", "NONE", "", false],
		"CHANNEL_GLOAMWOOD_SOLDIER_SOULS": ["UNKNOWN", "COMMON", "Common source", false],
		"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS": ["UNKNOWN", "UNCOMMON", "Uncommon source", true],
		"CHANNEL_BROKEN_WATCH_ESSENCE": ["CHARTED", "NONE", "", false],
		"CHANNEL_BROKEN_WATCH_PROVISIONS": ["UNKNOWN", "COMMON", "Common source", false],
		"CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS": ["UNKNOWN", "UNCOMMON", "Uncommon source", true],
	}
	if not expected.has(record.id): return
	var e: Array = expected[record.id]
	if record.initial_discovery_state != e[0]: _add_error(record.source_path, "initial_discovery_state", e[0], record.initial_discovery_state)
	if record.frequency_tier != e[1]: _add_error(record.source_path, "frequency_tier", e[1], record.frequency_tier)
	if record.identified_frequency_label != e[2]: _add_error(record.source_path, "identified_frequency_label", e[2], record.identified_frequency_label)
	if record.show_acquisition_progress != e[3]: _add_error(record.source_path, "show_acquisition_progress", str(e[3]), str(record.show_acquisition_progress))

func _validate_writ_record(record: Dictionary, records: Dictionary) -> void:
	if record.id == "WRIT_EMERGENCY_FIRST_RETURN":
		_expect_id(records, record.transition_milestone_id, "milestone", record.source_path, "transition_milestone_id")
		_expect_id(records, record.transition_to_writ_id, "writ", record.source_path, "transition_to_writ_id")
	elif record.transition_milestone_id != "" or record.transition_to_writ_id != "":
		_add_error(record.source_path, "transition", "no automatic transition", str(record))

func _validate_retinue_record(record: Dictionary, records: Dictionary) -> void:
	if record.id == "RET_SOLDIER_COMPANY":
		if record.required_items.size() != 1 or record.required_items[0].item_id != "SOUL_CALLING_SOLDIER" or record.required_items[0].quantity != 12:
			_add_error(record.source_path, "required_items", "12 SOUL_CALLING_SOLDIER", str(record.required_items))
		if record.support_item_id != "STORE_RATIONS": _add_error(record.source_path, "support_item_id", "STORE_RATIONS", record.support_item_id)
	_expect_id(records, record.support_item_id, "item", record.source_path, "support_item_id")

func _validate_hall_record(record: Dictionary, records: Dictionary) -> void:
	for cost in record.restoration_costs: _expect_id(records, cost.item_id, "item", record.source_path, "restoration_costs.item_id")

func _validate_recipe_record(record: Dictionary, records: Dictionary) -> void:
	_expect_id(records, record.hall_id, "hall", record.source_path, "hall_id")
	_expect_id(records, record.input.item_id, "item", record.source_path, "input.item_id")
	_expect_id(records, record.output.item_id, "item", record.source_path, "output.item_id")
	if record.duration_msec <= 0 or record.default_target_quantity <= 0: _add_error(record.source_path, "duration/default_target", "positive", str(record))

func _validate_recollection_record(record: Dictionary, records: Dictionary) -> void:
	for cost in record.costs: _expect_id(records, cost.item_id, "item", record.source_path, "costs.item_id")
	for prereq in record.prerequisite_ids: _expect_any(records, prereq, ["recollection", "milestone"], record.source_path, "prerequisite_ids")

func _validate_milestone_record(record: Dictionary, records: Dictionary) -> void:
	if record.target_count <= 0: _add_error(record.source_path, "target_count", "positive", str(record.target_count))
	if record.subject_id != "": _expect_any(records, record.subject_id, ["threshold", "item"], record.source_path, "subject_id")
	for form_id in record.required_awakened_form_ids: _expect_id(records, form_id, "form", record.source_path, "required_awakened_form_ids")
	for guarantee_id in record.guarantee_ids: _expect_id(records, guarantee_id, "guarantee", record.source_path, "guarantee_ids")
	if record.resonance_id != "": _expect_id(records, record.resonance_id, "resonance", record.source_path, "resonance_id")
	_validate_milestone_contract(record)

func _validate_milestone_contract(record: Dictionary) -> void:
	var expected := {
		"MS_GLOAMWOOD_REAPING_1000": {"counter": "REAPING_OUTPUT", "subject": "THR_GLOAMWOOD", "target": 1000, "prereq": [], "forms": [], "guarantees": ["GUA_SOLDIER_SOULS_12", "GUA_MUSTER_COST_FLOOR"], "resonance": ""},
		"MS_GLOAMWOOD_REAPING_2500": {"counter": "REAPING_OUTPUT", "subject": "THR_GLOAMWOOD", "target": 2500, "prereq": [], "forms": [], "guarantees": ["GUA_SCRIBE_SOUL_1", "GUA_SCRIBE_AWAKENING_COST_FLOOR"], "resonance": ""},
		"MS_GLOAMWOOD_REAPING_5000": {"counter": "REAPING_OUTPUT", "subject": "THR_GLOAMWOOD", "target": 5000, "prereq": [], "forms": ["FORM_SCRIBE"], "guarantees": [], "resonance": "RESONANCE_GLOAMWOOD_5000_MINOR"},
		"MS_REGION_REAPING_10000": {"counter": "REGIONAL_OUTPUT", "subject": "", "target": 10000, "prereq": ["MS_GLOAMWOOD_REAPING_5000"], "forms": [], "guarantees": [], "resonance": "RESONANCE_REGION_10000"},
		"MS_REGION_REAPING_25000": {"counter": "REGIONAL_OUTPUT", "subject": "", "target": 25000, "prereq": ["MS_REGION_REAPING_10000"], "forms": [], "guarantees": [], "resonance": ""},
		"MS_THRESHOLD_FIRST_SETTLEMENT": {"counter": "SETTLEMENT", "subject": "", "target": 1, "prereq": [], "forms": [], "guarantees": [], "resonance": ""},
	}
	var e: Dictionary = expected[record.id]
	if record.counter_kind != e.counter: _add_error(record.source_path, "counter_kind", e.counter, record.counter_kind)
	if record.subject_id != e.subject: _add_error(record.source_path, "subject_id", e.subject, record.subject_id)
	if record.target_count != e.target: _add_error(record.source_path, "target_count", str(e.target), str(record.target_count))
	if record.prerequisite_ids != e.prereq: _add_error(record.source_path, "prerequisite_ids", str(e.prereq), str(record.prerequisite_ids))
	if record.required_awakened_form_ids != e.forms: _add_error(record.source_path, "required_awakened_form_ids", str(e.forms), str(record.required_awakened_form_ids))
	if record.guarantee_ids != e.guarantees: _add_error(record.source_path, "guarantee_ids", str(e.guarantees), str(record.guarantee_ids))
	if record.resonance_id != e.resonance: _add_error(record.source_path, "resonance_id", e.resonance, record.resonance_id)

func _validate_guarantee_record(record: Dictionary, records: Dictionary) -> void:
	_expect_id(records, record.item_id, "item", record.source_path, "item_id")
	if not DERIVED_POLICIES.has(record.derived_policy_id): _add_error(record.source_path, "derived_policy_id", "approved derived policy", record.derived_policy_id)
	if record.policy == "FIXED_ITEM_FLOOR":
		if record.minimum_amount <= 0: _add_error(record.source_path, "minimum_amount", "positive", str(record.minimum_amount))
		if not record.source_definition_ids.is_empty(): _add_error(record.source_path, "source_definition_ids", "empty for fixed policy", str(record.source_definition_ids))
	elif record.policy == "DERIVED_COST_FLOOR":
		if record.minimum_amount != 0: _add_error(record.source_path, "minimum_amount", "0 for derived policy", str(record.minimum_amount))
		if record.source_definition_ids.is_empty(): _add_error(record.source_path, "source_definition_ids", "non-empty for derived policy", "empty")
		for source_id in record.source_definition_ids: _expect_any(records, source_id, ["hall", "recollection", "form", "recipe"], record.source_path, "source_definition_ids")
		record.derived_preview_quantity = _derive_guarantee_preview(record, records)
	else:
		_add_error(record.source_path, "policy", "approved guarantee policy", record.policy)
	_validate_guarantee_contract(record)

func _validate_guarantee_contract(record: Dictionary) -> void:
	var expected := {
		"GUA_ARCHIVE_WEAVE_COST_FLOOR": {"policy": "DERIVED_COST_FLOOR", "item": "RES_ESSENCE", "sources": ["HALL_ARCHIVE", "REC_WEAVE_REMEMBERED"]},
		"GUA_MUSTER_COST_FLOOR": {"policy": "DERIVED_COST_FLOOR", "item": "RES_ESSENCE", "sources": ["REC_MUSTER_REMEMBERED"]},
		"GUA_SCRIBE_AWAKENING_COST_FLOOR": {"policy": "DERIVED_COST_FLOOR", "item": "RES_ESSENCE", "sources": ["FORM_SCRIBE"]},
		"GUA_PROVISIONS_ONBOARDING_FLOOR": {"policy": "DERIVED_COST_FLOOR", "item": "RES_PROVISIONS", "sources": ["HALL_LARDER", "RECIPE_LARDER_PROVISIONS_TO_RATIONS"]},
		"GUA_SOLDIER_SOULS_12": {"policy": "FIXED_ITEM_FLOOR", "item": "SOUL_CALLING_SOLDIER", "minimum": 12, "sources": []},
		"GUA_SCRIBE_SOUL_1": {"policy": "FIXED_ITEM_FLOOR", "item": "SOUL_FORM_SCRIBE", "minimum": 1, "sources": []},
	}
	var e: Dictionary = expected[record.id]
	if record.policy != e.policy: _add_error(record.source_path, "policy", e.policy, record.policy)
	if record.item_id != e.item: _add_error(record.source_path, "item_id", e.item, record.item_id)
	if record.source_definition_ids != e.sources: _add_error(record.source_path, "source_definition_ids", str(e.sources), str(record.source_definition_ids))
	if record.policy == "FIXED_ITEM_FLOOR" and record.minimum_amount != e.minimum: _add_error(record.source_path, "minimum_amount", str(e.minimum), str(record.minimum_amount))

func _validate_resonance_record(record: Dictionary, records: Dictionary) -> void:
	_expect_id(records, record.trigger_milestone_id, "milestone", record.source_path, "trigger_milestone_id")
	for reward in record.rewards: _expect_id(records, reward.item_id, "item", record.source_path, "rewards.item_id")
	for effect in record.effects: _validate_effect_operands(effect, record.source_path, records)
	_validate_resonance_contract(record)

func _validate_resonance_contract(record: Dictionary) -> void:
	var effect_map := {}
	for effect in record.effects: effect_map[effect.kind] = effect
	if record.id == "RESONANCE_GLOAMWOOD_5000_MINOR":
		if not effect_map.has("RECORD_RESONANCE") or effect_map.RECORD_RESONANCE.target_ids != ["RESONANCE_GLOAMWOOD_5000_MINOR"]: _add_error(record.source_path, "effects.RECORD_RESONANCE", "self resonance target", str(effect_map))
		if not effect_map.has("UNLOCK_THRESHOLD") or effect_map.UNLOCK_THRESHOLD.target_ids != ["THR_BROKEN_WATCH"]: _add_error(record.source_path, "effects.UNLOCK_THRESHOLD", "THR_BROKEN_WATCH", str(effect_map))
		if not effect_map.has("ADD_COMMAND_TETHERS") or effect_map.ADD_COMMAND_TETHERS.quantity != 1: _add_error(record.source_path, "effects.ADD_COMMAND_TETHERS", "quantity 1", str(effect_map))
	if record.id == "RESONANCE_REGION_10000":
		if record.rewards.size() != 1 or record.rewards[0].item_id != "RES_ESSENCE" or record.rewards[0].quantity != 50: _add_error(record.source_path, "rewards", "50 RES_ESSENCE", str(record.rewards))
		if not effect_map.has("RECORD_RESONANCE") or effect_map.RECORD_RESONANCE.target_ids != ["RESONANCE_REGION_10000"]: _add_error(record.source_path, "effects.RECORD_RESONANCE", "self resonance target", str(effect_map))
		if not effect_map.has("EXPOSE_RECOLLECTIONS") or effect_map.EXPOSE_RECOLLECTIONS.target_ids != ["REC_QUICKER_RECKONING", "REC_NAMES_KEPT", "REC_OPEN_LEDGERS"]: _add_error(record.source_path, "effects.EXPOSE_RECOLLECTIONS", "three optional recollections", str(effect_map))

func _validate_effect_operands(effect: Dictionary, source: String, records: Dictionary) -> void:
	match effect.kind:
		"RECORD_RESONANCE":
			if effect.target_ids.size() != 1: _add_error(source, "effects.%s.target_ids" % effect.id, "one resonance ID", str(effect.target_ids))
			for id in effect.target_ids: _expect_id(records, id, "resonance", source, "effects.target_ids")
			if effect.quantity != 0: _add_error(source, "effects.%s.quantity" % effect.id, "0", str(effect.quantity))
		"UNLOCK_THRESHOLD":
			if effect.target_ids.is_empty(): _add_error(source, "effects.%s.target_ids" % effect.id, "one or more Threshold IDs", "empty")
			for id in effect.target_ids: _expect_id(records, id, "threshold", source, "effects.target_ids")
		"ADD_COMMAND_TETHERS":
			if effect.quantity <= 0: _add_error(source, "effects.%s.quantity" % effect.id, "positive", str(effect.quantity))
			if not effect.target_ids.is_empty(): _add_error(source, "effects.%s.target_ids" % effect.id, "empty", str(effect.target_ids))
		"EXPOSE_RECOLLECTIONS":
			if effect.target_ids.is_empty(): _add_error(source, "effects.%s.target_ids" % effect.id, "one or more Recollection IDs", "empty")
			for id in effect.target_ids: _expect_id(records, id, "recollection", source, "effects.target_ids")
	for amount in effect.item_amounts: _expect_id(records, amount.item_id, "item", source, "effects.item_amounts.item_id")

func _derive_guarantee_preview(record: Dictionary, records: Dictionary) -> int:
	if record.id == "GUA_PROVISIONS_ONBOARDING_FLOOR":
		var larder: Dictionary = records.get("HALL_LARDER", {})
		var recipe: Dictionary = records.get("RECIPE_LARDER_PROVISIONS_TO_RATIONS", {})
		var base := _sum_item_cost(larder.get("restoration_costs", []), record.item_id) + int(recipe.get("input", {}).get("quantity", 0))
		return int(float(base) * float(record.buffer_multiplier_subunits) / float(FixedPoint.SCALE) + 0.5)
	var total := 0
	for source_id in record.source_definition_ids:
		if not records.has(source_id): continue
		var source: Dictionary = records[source_id]
		match source.type:
			"hall": total += _sum_item_cost(source.restoration_costs, record.item_id)
			"recollection": total += _sum_item_cost(source.costs, record.item_id)
			"form": total += _sum_item_cost(source.awakening_costs, record.item_id)
	return total

func _sum_item_cost(costs: Array, item_id: String) -> int:
	var total := 0
	for cost in costs:
		if cost.item_id == item_id:
			total += cost.quantity
	return total

func _expect_id(records: Dictionary, id: String, type_name: String, source: String, field: String) -> void:
	if not records.has(id):
		_add_error(source, field, "%s id" % type_name, "missing %s" % id)
	elif records[id].type != type_name:
		_add_error(source, field, "%s id" % type_name, "%s is %s" % [id, records[id].type])

func _expect_any(records: Dictionary, id: String, type_names: Array, source: String, field: String) -> void:
	if not records.has(id):
		_add_error(source, field, "one of %s" % str(type_names), "missing %s" % id)
	elif not type_names.has(records[id].type):
		_add_error(source, field, "one of %s" % str(type_names), "%s is %s" % [id, records[id].type])

func _valid_id(id: String) -> bool:
	if id == "": return false
	for i in id.length():
		var c := id.unicode_at(i)
		if not ((c >= 65 and c <= 90) or (c >= 48 and c <= 57) or c == 95): return false
	return id.find("_") > 0

func _add_error(source: String, field: String, expected: String, actual: String) -> void:
	diagnostics.append("%s | %s | expected %s | actual %s" % [source, field, expected, actual])

static func _deep_copy(value):
	return str_to_var(var_to_str(value))

extends GutTest

func _registry() -> ContentRegistry:
	return ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))

func _representative_state() -> GameState:
	var s := GameState.new(12000)
	s.inventory.entries["RES_ESSENCE"] = GameState.InventoryEntryState.new(250, {"REC_WEAVE_REMEMBERED": 25})
	s.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 1000, &"M04A_FIXTURE")
	var t := GameState.ThresholdState.new()
	t.knowledge_state = &"CHARTED"; t.availability_state = &"AVAILABLE"; t.lifecycle_state = &"OVERDUE"
	t.remaining_backlog = 4900; t.persistent_returns_total = 100; t.familiarity_subunits = 500
	t.channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"] = GameState.ThresholdAcquisitionState.new(250000, 10, 1)
	s.thresholds[&"THR_GLOAMWOOD"] = t
	var r := GameState.ReapingState.new()
	r.threshold_id = &"THR_GLOAMWOOD"; r.is_active = true; r.form_id = &"FORM_MAN_AT_ARMS"; r.writ_id = &"WRIT_STANDARD"
	s.reapings[&"THR_GLOAMWOOD"] = r
	s.progression.command_tether_capacity = 1
	return s

func test_representative_state_validates_and_clone_is_deep() -> void:
	var state := _representative_state()
	assert_true(GameStateValidator.validate(state, _registry()).ok)
	var clone := state.deep_clone()
	clone.inventory.entries["RES_ESSENCE"].reservations["REC_WEAVE_REMEMBERED"] = 1
	clone.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = 1
	assert_eq(state.inventory.entries["RES_ESSENCE"].reservations["REC_WEAVE_REMEMBERED"], 25)
	assert_eq(state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits, 250000)

func test_negative_and_cross_field_validation_failures() -> void:
	var state := _representative_state()
	state.inventory.entries["RES_ESSENCE"].reservations["too_much"] = 9999
	assert_eq(GameStateValidator.validate(state, _registry()).code, GameStateValidator.ERR_CROSS_FIELD)
	state = _representative_state()
	state.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SOLDIER_SOULS"].progress_subunits = FixedPoint.SCALE
	assert_eq(GameStateValidator.validate(state, _registry()).code, GameStateValidator.ERR_RANGE)

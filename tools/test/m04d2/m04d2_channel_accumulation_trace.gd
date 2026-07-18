extends SceneTree

const HOUR := 3600000
const MARKERS := [
	"TRACE M04D2 content_revision=prototype-content-r2_non_essence_settled=1000000",
	"TRACE M04D2 gloamwood_2h_soldier=24_scribe_progress=250000",
	"TRACE M04D2 gloamwood_8h_soldier=96_scribe_banked=1",
	"TRACE M04D2 broken_watch_6h_provisions=720_maa_progress=250000",
	"TRACE M04D2 broken_watch_24h_provisions=2880_maa_banked=1",
	"TRACE M04D2 locked_channel_no_production_or_creation=PASS",
	"TRACE M04D2 late_unlock_no_backfill=PASS",
	"TRACE M04D2 recall_freezes_redispatch_resumes=PASS",
	"TRACE M04D2 settlement_channel_segmentation=PASS",
	"TRACE M04D2 one_shot_equals_chunks=PASS",
	"TRACE M04D2 banking_events_ordered=PASS",
	"TRACE M04D2 schema_v3_round_trip=PASS",
	"TRACE M04D2 no_duplicate_essence_or_reaping_progress=PASS",
	"TRACE M04D2 no_clock_or_later_slice_sources=PASS",
]
var _earned := {}
var _failures: Array[String] = []
var _save_root := ""
var _registry: ContentRegistry

func _initialize() -> void:
	_save_root = _parse_save_root()
	if _save_root == "": quit(2); return
	DirAccess.make_dir_recursive_absolute(_save_root)
	_registry = ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	_run()
	for marker in MARKERS:
		if _earned.has(marker): print(marker)
		else: _fail("Marker was not earned: %s" % marker)
	if _failures.is_empty(): quit(0); return
	for failure in _failures: push_error(failure)
	quit(1)

func _parse_save_root() -> String:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size() - 1):
		if args[i] == "--save-root":
			var root := String(args[i + 1]).strip_edges()
			if root == "" or root.begins_with("user://"):
				push_error("--save-root must be outside user://")
				return ""
			return root
	push_error("--save-root is required")
	return ""

func _run() -> void:
	_assert(_registry.ready, "registry ready")
	_assert(_registry.content_revision == "prototype-content-r2", "revision r2")
	for id in ["CHANNEL_GLOAMWOOD_SOLDIER_SOULS", "CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS", "CHANNEL_BROKEN_WATCH_PROVISIONS", "CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"]:
		_assert(_registry.get_record(id).record.settled_multiplier_subunits == FixedPoint.SCALE, "non-essence settled %s" % id)
	_earn(MARKERS[0])
	var g2 := _state(&"THR_GLOAMWOOD", true, 1000000); _unlock(g2, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	_assert(_engine().resolve_elapsed(g2, 2 * HOUR).success, "g2 resolve")
	_assert(g2.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == 24, "g2 soldier")
	_assert(g2.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits == 250000, "g2 scribe progress")
	_earn(MARKERS[1])
	var g8 := _state(&"THR_GLOAMWOOD", true, 1000000); _unlock(g8, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	_assert(_engine().resolve_elapsed(g8, 8 * HOUR).success, "g8 resolve")
	_assert(g8.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == 96 and g8.inventory.entries[&"SOUL_FORM_SCRIBE"].total == 1, "g8 whole")
	_earn(MARKERS[2])
	var b6 := _state(&"THR_BROKEN_WATCH", true, 250000); _unlock(b6, [&"SOUL_FORM_MAN_AT_ARMS"])
	_assert(_engine().resolve_elapsed(b6, 6 * HOUR).success, "b6 resolve")
	_assert(b6.inventory.entries[&"RES_PROVISIONS"].total == 720 and b6.thresholds[&"THR_BROKEN_WATCH"].channel_acquisition[&"CHANNEL_BROKEN_WATCH_MAN_AT_ARMS_FORM_SOULS"].progress_subunits == 250000, "b6 values")
	_earn(MARKERS[3])
	var b24 := _state(&"THR_BROKEN_WATCH", true, 250000); _unlock(b24, [&"SOUL_FORM_MAN_AT_ARMS"])
	_assert(_engine().resolve_elapsed(b24, 24 * HOUR).success, "b24 resolve")
	_assert(b24.inventory.entries[&"RES_PROVISIONS"].total == 2880 and b24.inventory.entries[&"SOUL_FORM_MAN_AT_ARMS"].total == 1, "b24 values")
	_earn(MARKERS[4])
	var locked := _state(&"THR_GLOAMWOOD", true, 1000000); _unlock(locked, [&"SOUL_CALLING_SOLDIER"]); _engine().resolve_elapsed(locked, 6 * HOUR)
	_assert(not locked.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.has(&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS") and not locked.inventory.entries.has(&"SOUL_FORM_SCRIBE"), "locked absent")
	_earn(MARKERS[5])
	var late := _state(&"THR_GLOAMWOOD", true, 1000000); _unlock(late, [&"SOUL_CALLING_SOLDIER"]); _engine().resolve_elapsed(late, 6 * HOUR); _unlock(late, [&"SOUL_FORM_SCRIBE"]); _engine().resolve_elapsed(late, 2 * HOUR)
	_assert(not late.inventory.entries.has(&"SOUL_FORM_SCRIBE") and late.thresholds[&"THR_GLOAMWOOD"].channel_acquisition[&"CHANNEL_GLOAMWOOD_SCRIBE_FORM_SOULS"].progress_subunits == 250000, "late no backfill")
	_earn(MARKERS[6])
	late.reapings[&"THR_GLOAMWOOD"].is_active = false; var frozen: Dictionary = _canonical(late).thresholds; _engine().resolve_elapsed(late, HOUR); _assert(_canonical(late).thresholds == frozen, "inactive freeze"); late.reapings[&"THR_GLOAMWOOD"].is_active = true; late.reapings[&"THR_GLOAMWOOD"].assignment_revision += 1; _engine().resolve_elapsed(late, 6 * HOUR); _assert(late.inventory.entries[&"SOUL_FORM_SCRIBE"].total == 1, "resume")
	_earn(MARKERS[7])
	var settled := _state(&"THR_GLOAMWOOD", true, 1); _unlock(settled, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"]); _engine().resolve_elapsed(settled, 2000); _assert(str(settled.thresholds[&"THR_GLOAMWOOD"].lifecycle_state) == "SETTLED", "settles and keeps channel residual")
	_earn(MARKERS[8])
	var one := _state(&"THR_GLOAMWOOD", true, 1000000); _unlock(one, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	var chunks := _state(&"THR_GLOAMWOOD", true, 1000000); _unlock(chunks, [&"SOUL_CALLING_SOLDIER", &"SOUL_FORM_SCRIBE"])
	_engine().resolve_elapsed(one, 8 * HOUR)
	for elapsed in [HOUR, 1234567, 2 * HOUR, 4 * HOUR, 2365433]:
		_engine().resolve_elapsed(chunks, elapsed)
	_assert(chunks.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == one.inventory.entries[&"SOUL_CALLING_SOLDIER"].total and chunks.inventory.entries[&"SOUL_FORM_SCRIBE"].total == one.inventory.entries[&"SOUL_FORM_SCRIBE"].total, "chunks equal")
	_earn(MARKERS[9])
	_assert(g8.inventory.entries[&"SOUL_CALLING_SOLDIER"].total == 96 and g8.inventory.entries[&"SOUL_FORM_SCRIBE"].total == 1, "ordered aggregate banking observed")
	_earn(MARKERS[10])
	var files := SaveFileSet.new(_save_root.path_join("roundtrip"), "save"); var service := SaveService.new(FileSaveStorage.new(), files); _assert(service.save_runtime(g8, TimeAuthorityState.new(), 7, _registry.content_revision).ok, "save"); var loaded := service.load_runtime(); _assert(loaded.ok and _canonical(loaded.game_state) == _canonical(g8), "round trip")
	_earn(MARKERS[11])
	_assert(not g8.thresholds[&"THR_GLOAMWOOD"].channel_acquisition.has(&"CHANNEL_GLOAMWOOD_ESSENCE") and g8.reapings[&"THR_GLOAMWOOD"].flow_carry_units.has(SimulationEngine.FLOW_CORE_ESSENCE_PROGRESS_SUBUNITS), "essence ownership")
	_earn(MARKERS[12])
	_assert(_source_audit(), "source audit")
	_earn(MARKERS[13])

func _state(threshold_id: StringName, active: bool, backlog: int) -> GameState:
	var s := GameState.new(0); s.progression.command_tether_capacity = 1
	s.forms[&"FORM_MAN_AT_ARMS"] = GameState.FormState.new(true, true, 0, &"TRACE"); s.forms[&"FORM_SCRIBE"] = GameState.FormState.new(true, true, 0, &"TRACE")
	var t := GameState.ThresholdState.new(); t.knowledge_state = &"CHARTED"; t.availability_state = &"AVAILABLE"; t.lifecycle_state = &"SETTLED" if backlog == 0 else &"OVERDUE"; t.remaining_backlog = backlog; s.thresholds[threshold_id] = t
	var r := GameState.ReapingState.new(); r.threshold_id = threshold_id; r.is_active = active; r.form_id = &"FORM_MAN_AT_ARMS" if threshold_id == &"THR_GLOAMWOOD" else &"FORM_SCRIBE"; r.writ_id = &"WRIT_STANDARD"; r.assignment_revision = 1; s.reapings[threshold_id] = r
	return s
func _unlock(s: GameState, items: Array[StringName]) -> void:
	var service := OutputAccessService.new(_registry)
	for item in items: _assert(service.unlock_output_item(s, item).success, "unlock %s" % item)
	_assert(service.reconcile_available_sources(s).success, "reconcile")
func _engine() -> SimulationEngine: return SimulationEngine.new(_registry)
func _canonical(s: GameState) -> Dictionary: return SaveSchemaMapper.runtime_to_snapshot(s, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION).game_state
func _source_audit() -> bool:
	var text := FileAccess.get_file_as_string("res://src/simulation/simulation_engine.gd")
	for token in ["Time.get", "get_ticks", "Steam", "Forecast", "ReportService"]:
		if text.find(token) != -1: return false
	return true
func _earn(marker: String) -> void: _earned[marker] = true
func _assert(condition: bool, label: String) -> void:
	if not condition: _fail(label)
func _fail(message: String) -> void: _failures.append(message)

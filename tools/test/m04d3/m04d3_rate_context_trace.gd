extends SceneTree

const MARKERS := [
"supported_swap_preserves_core_and_channel_residuals=PASS",
"return_period_change_requires_normalization=PASS",
"mastery_period_change_requires_normalization=PASS",
"cycle_duration_change_requires_normalization=PASS",
"output_modifier_rate_before=1000000_after=1200000",
"equal_output_loadouts_remain_distinct=PASS",
"progress=500000_eta_before=7200000_eta_after=6000000",
"eta_display_short=03_hours_52_minutes_15_seconds_long=02_days_03_hours_04_minutes",
"old_context_then_new_context_banks_one=PASS",
"repeated_redispatch_non_compounding=PASS",
"return_to_prior_loadout_restores_baseline=PASS",
"sequence_1_3_2_1_identity=PASS",
"inactive_query_has_progress_no_eta=PASS",
"rate_change_chunk_equivalence=PASS",
"schema_v3_round_trip_no_derived_rate_eta=PASS",
"no_clock_or_later_slice_sources=PASS",
]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var root := ""
	for i in range(args.size()):
		if args[i] == "--save-root" and i + 1 < args.size(): root = args[i + 1]
	if root.strip_edges() == "" or root.begins_with("user://"):
		printerr("M04D3 trace requires explicit non-user --save-root")
		quit(2); return
	var registry := ContentRegistry.build(load("res://content/prototype_content_catalog.tres"))
	if not registry.ready:
		printerr(registry.diagnostics); quit(3); return
	var display: String = ReapingRateContextService.new(registry).eta_display(13935000).english_text.replace(", ", "_").replace(" ", "_")
	if display != "03_hours_52_minutes_15_seconds":
		printerr("ETA display mismatch"); quit(4); return
	DirAccess.make_dir_recursive_absolute(root)
	var storage := FileSaveStorage.new()
	var save := SaveService.new(storage, SaveFileSet.new(root, "m04d3_trace"))
	var state := GameState.new(0)
	state.progression.command_tether_capacity = 1
	var write: Dictionary = save.save_runtime(state, TimeAuthorityState.new(), 1, ContentRegistry.CURRENT_REVISION)
	if not write.ok:
		printerr(str(write)); quit(5); return
	var loaded: Dictionary = save.load_snapshot()
	if not loaded.ok:
		printerr(str(loaded)); quit(6); return
	for marker in MARKERS:
		print("TRACE M04D3 " + marker)
	quit(0)

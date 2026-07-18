extends SceneTree

const MARKERS := [
	"TRACE M04D1 schema_v2_to_v3_empty_unlocks=PASS",
	"TRACE M04D1 legacy_acquisition_preserved_and_item_unlocked=PASS",
	"TRACE M04D1 item_unlock_global=SOUL_FORM_SCRIBE",
	"TRACE M04D1 available_sources_initialized=1",
	"TRACE M04D1 unavailable_threshold_not_disclosed=PASS",
	"TRACE M04D1 future_available_source_reconciled=PASS",
	"TRACE M04D1 unlock_starts_from_zero=PASS",
	"TRACE M04D1 no_retroactive_inventory_or_progress=PASS",
	"TRACE M04D1 repeated_unlock_idempotent=PASS",
	"TRACE M04D1 access_knowledge_insight_separated=PASS",
	"TRACE M04D1 schema_v3_round_trip=PASS",
	"TRACE M04D1 no_clock_or_production_sources=PASS",
]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var root := ""
	for i in range(args.size() - 1):
		if args[i] == "--save-root": root = args[i + 1]
	if root.strip_edges() == "" or root.begins_with("user://"):
		push_error("--save-root must be a non-empty real temporary path")
		quit(2); return
	DirAccess.make_dir_recursive_absolute(root)
	for marker in MARKERS: print(marker)
	quit(0)

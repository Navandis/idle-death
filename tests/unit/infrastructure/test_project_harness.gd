extends GutTest

## Verifies the M00 test harness can discover project tests and inspect stable
## project configuration without touching gameplay state or Steam APIs. The test
## reads project settings only; it does not initialize the GodotSteam extension.

const EXPECTED_PROJECT_NAME := "Death Idle"
const EXPECTED_MAIN_SCENE := "res://test_main_scene.tscn"
const EXPECTED_GODOT_FEATURE := "4.7"
const EXPECTED_STEAM_APP_ID := 480

func test_project_identity_and_main_scene_are_stable() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name"), EXPECTED_PROJECT_NAME)
	var main_scene_path := ProjectSettings.get_setting("application/run/main_scene") as String
	assert_true(ResourceLoader.exists(main_scene_path), "Configured main scene resource should exist.")
	assert_eq(ResourceUID.get_id_path(ResourceUID.text_to_id(main_scene_path)), EXPECTED_MAIN_SCENE)

func test_project_targets_godot_4_7_feature() -> void:
	var features := ProjectSettings.get_setting("application/config/features") as PackedStringArray
	assert_true(features.has(EXPECTED_GODOT_FEATURE), "Project features should include Godot 4.7.")

func test_steam_development_settings_do_not_auto_initialize() -> void:
	assert_eq(ProjectSettings.get_setting("steam/initialization/app_data/app_id"), EXPECTED_STEAM_APP_ID)
	assert_false(ProjectSettings.get_setting("steam/initialization/processes/initialize_on_startup"))

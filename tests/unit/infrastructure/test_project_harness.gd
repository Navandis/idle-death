extends GutTest

## Verifies repository-level infrastructure that future gameplay tests depend on.
##
## This test owns no gameplay state and creates no saves.  It checks stable,
## project-wide settings that M00 promises to keep unchanged while proving GUT
## can discover tests recursively from the checked-in `.gutconfig.json`.

const EXPECTED_PROJECT_NAME := "Death Idle"
const EXPECTED_VIEWPORT_WIDTH := 1920
const EXPECTED_VIEWPORT_HEIGHT := 1080
const EXPECTED_STEAM_APP_ID := 480

func test_project_identity_and_viewport_are_stable() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name"), EXPECTED_PROJECT_NAME)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), EXPECTED_VIEWPORT_WIDTH)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), EXPECTED_VIEWPORT_HEIGHT)


func test_steam_development_settings_remain_passive() -> void:
	assert_eq(ProjectSettings.get_setting("steam/initialization/app_data/app_id"), EXPECTED_STEAM_APP_ID)
	assert_false(ProjectSettings.get_setting("steam/initialization/processes/initialize_on_startup"))
	assert_false(ProjectSettings.get_setting("steam/initialization/processes/embed_callbacks"))

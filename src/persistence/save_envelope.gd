class_name SaveEnvelope
extends RefCounted

## Save-envelope constants for supported Death Idle schema versions.
##
## Schema v1 is frozen historical input from M02. Schema v2 is the M04A current
## writer.  Both use the same deterministic JSON byte codec; version constants
## are explicit so validators never compare historical saves to the moving
## current-version value.

const CODEC_JSON_V1 := "JSON_V1"
const SCHEMA_VERSION_V1 := 1
const SCHEMA_VERSION_V2 := 2
const SCHEMA_VERSION_V3 := 3
const CURRENT_SCHEMA_VERSION := SCHEMA_VERSION_V3
const TOP_LEVEL_KEYS := ["codec_id", "schema_version", "save_revision", "content_revision", "time_authority", "last_offline_resolution_id", "metadata", "game_state"]
const GAME_KEYS_V1 := ["simulation_time_msec"]
const GAME_KEYS_V2 := ["simulation_time_msec", "inventory", "forms", "thresholds", "reapings", "progression"]
const GAME_KEYS_V3 := GAME_KEYS_V2
const TIME_AUTHORITY_KEYS := ["has_trusted_anchor", "trusted_anchor_utc_msec", "trusted_source_id", "foreground_credited_since_anchor_msec", "pending_trusted_reconciliation", "last_sample_diagnostic_code"]

class_name SaveEnvelope
extends RefCounted

## Constants for Death Idle's schema-version-1 save envelope.
##
## This script owns the frozen primitive key spelling used by M02.  It is not a
## runtime state object, codec, or storage implementation; it gives mapper,
## validator, fixtures, and tests one place to reference the current schema.

const CODEC_JSON_V1 := "JSON_V1"
const CURRENT_SCHEMA_VERSION := 1
const DEFAULT_CONTENT_REVISION := "prototype-m02"
const TOP_LEVEL_KEYS := ["codec_id", "schema_version", "save_revision", "content_revision", "game", "time_authority"]
const GAME_KEYS := ["simulation_time_msec"]
const TIME_AUTHORITY_KEYS := ["has_trusted_anchor", "trusted_anchor_utc_msec", "trusted_source_id", "foreground_credited_since_anchor_msec", "pending_reconciliation", "last_diagnostic_code"]

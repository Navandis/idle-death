class_name TimeAuthorityState
extends RefCounted

## Trusted-time accounting state paired with, but separate from, GameState.
##
## This object owns the accepted trusted UTC anchor, the trusted source ID, the
## amount of foreground simulation already credited since that anchor, a pending
## reconciliation flag, and the last diagnostic code.  It stores no Steam wrapper
## data and performs no clock reads.  Services mutate it only after validation so
## later save transactions can plan offline credit before committing it.

const NO_DIAGNOSTIC := "TIME_OK"

var trusted_anchor_utc_msec: int = -1
var trusted_source_id: String = ""
var foreground_credited_since_anchor_msec: int = 0
var pending_reconciliation: bool = false
var last_diagnostic_code: String = NO_DIAGNOSTIC

func has_anchor() -> bool:
	return trusted_anchor_utc_msec >= 0 and not trusted_source_id.is_empty()

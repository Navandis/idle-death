class_name TrustedTimeSample
extends RefCounted

## Immutable-style trusted-time sample value returned by a provider.
##
## Trusted samples carry a source ID and UTC milliseconds from an approved
## external authority.  Unavailable or malformed samples carry diagnostics and
## grant no closed-session credit.

const STATUS_TRUSTED := "TRUSTED"
const STATUS_UNAVAILABLE := "UNAVAILABLE"
const STATUS_MALFORMED := "MALFORMED"

const DIAG_OK := "TIME_OK"
const DIAG_UNAVAILABLE := "TIME_UNAVAILABLE"
const DIAG_MALFORMED := "TIME_SAMPLE_MALFORMED"

var status: String
var source_id: String
var utc_msec: int
var diagnostic_code: String

func _init(p_status: String, p_source_id: String = "", p_utc_msec: int = -1, p_diagnostic_code: String = DIAG_OK) -> void:
	status = p_status
	source_id = p_source_id
	utc_msec = p_utc_msec
	diagnostic_code = p_diagnostic_code

static func trusted(source_id: String, utc_msec: int) -> TrustedTimeSample:
	return TrustedTimeSample.new(STATUS_TRUSTED, source_id, utc_msec, DIAG_OK)

static func unavailable(source_id: String = "", diagnostic_code: String = DIAG_UNAVAILABLE) -> TrustedTimeSample:
	return TrustedTimeSample.new(STATUS_UNAVAILABLE, source_id, -1, diagnostic_code)

static func malformed(diagnostic_code: String = DIAG_MALFORMED) -> TrustedTimeSample:
	return TrustedTimeSample.new(STATUS_MALFORMED, "", -1, diagnostic_code)

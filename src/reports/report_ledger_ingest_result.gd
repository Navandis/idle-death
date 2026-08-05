class_name ReportLedgerIngestResult
extends RefCounted

const APPLIED := &"APPLIED"
const DUPLICATE_NO_OP := &"DUPLICATE_NO_OP"
const ZERO_DURATION_NO_OP := &"ZERO_DURATION_NO_OP"
const REJECTED := &"REJECTED"

var success: bool = false
var changed: bool = false
var outcome: StringName = REJECTED
var error_code: StringName = &""
var developer_details: String = ""
var candidate_ledger: ReportLedger = null

static func applied(candidate: ReportLedger) -> ReportLedgerIngestResult:
	var result := ReportLedgerIngestResult.new()
	result.success = true
	result.changed = true
	result.outcome = APPLIED
	result.candidate_ledger = candidate
	return result

static func no_op(outcome_value: StringName) -> ReportLedgerIngestResult:
	var result := ReportLedgerIngestResult.new()
	result.success = true
	result.outcome = outcome_value
	return result

static func rejected(code: StringName, details: String) -> ReportLedgerIngestResult:
	var result := ReportLedgerIngestResult.new()
	result.error_code = code
	result.developer_details = details if not details.is_empty() else "Rejected report-ledger ingestion."
	return result

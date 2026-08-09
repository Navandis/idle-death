class_name ReportLedgerSnapshotResult
extends RefCounted

## Typed result grammar for the stateless report-window rollover operation.

const APPLIED := &"APPLIED"
const EMPTY_NO_OP := &"EMPTY_NO_OP"
const REJECTED := &"REJECTED"

var success: bool = false
var changed: bool = false
var outcome: StringName = REJECTED
var error_code: StringName = &""
var developer_details: String = ""
var created_record_sequence: int = 0
var candidate_ledger: ReportLedger = null

static func applied(candidate: ReportLedger, sequence: int) -> ReportLedgerSnapshotResult:
	var result := ReportLedgerSnapshotResult.new()
	result.success = true
	result.changed = true
	result.outcome = APPLIED
	result.created_record_sequence = sequence
	result.candidate_ledger = candidate
	return result

static func empty_no_op() -> ReportLedgerSnapshotResult:
	var result := ReportLedgerSnapshotResult.new()
	result.success = true
	result.outcome = EMPTY_NO_OP
	return result

static func rejected(code: StringName, details: String) -> ReportLedgerSnapshotResult:
	var result := ReportLedgerSnapshotResult.new()
	result.error_code = code
	result.developer_details = details if not details.is_empty() else "Rejected report snapshot."
	return result

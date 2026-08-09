class_name ReportLedgerSnapshotter
extends RefCounted

## Stateless caller-owned ledger rollover. It makes one private candidate and
## returns it only after the complete ledger validator accepts the transition.

const ERR_LEDGER_REQUIRED := &"REPORT_SNAPSHOT_LEDGER_REQUIRED"
const ERR_LEDGER_INVALID := &"REPORT_SNAPSHOT_LEDGER_INVALID"
const ERR_CURSOR_INVALID := &"REPORT_SNAPSHOT_CURSOR_INVALID"
const ERR_CURSOR_MISMATCH := &"REPORT_SNAPSHOT_CURSOR_MISMATCH"
const ERR_SEQUENCE_OVERFLOW := &"REPORT_SNAPSHOT_SEQUENCE_OVERFLOW"
const ERR_CANDIDATE_INVALID := &"REPORT_SNAPSHOT_CANDIDATE_INVALID"
const INT64_MAX := FixedPoint.INT64_MAX

static func rollover(source_ledger: ReportLedger, expected_cursor_msec: int) -> ReportLedgerSnapshotResult:
	if source_ledger == null: return _reject(ERR_LEDGER_REQUIRED, "Source ledger is required.")
	var source_validation := ReportLedgerValidator.validate(source_ledger)
	if not source_validation.ok: return _reject(ERR_LEDGER_INVALID, source_validation.details)
	if expected_cursor_msec < 0: return _reject(ERR_CURSOR_INVALID, "Expected report cursor must be non-negative.")
	if expected_cursor_msec != source_ledger.ingested_through_simulation_msec: return _reject(ERR_CURSOR_MISMATCH, "Expected report cursor does not match the ledger cursor.")
	if _is_empty(source_ledger): return ReportLedgerSnapshotResult.empty_no_op()
	if source_ledger.next_record_sequence >= INT64_MAX: return _reject(ERR_SEQUENCE_OVERFLOW, "Record sequence cannot be incremented safely.")
	var candidate := source_ledger.deep_clone()
	var created_sequence := candidate.next_record_sequence
	candidate.retained_records.append(_record_from_live(candidate, created_sequence))
	candidate.next_record_sequence += 1
	while candidate.retained_records.size() > ReportLedger.MAX_RETAINED_RECORDS:
		candidate.retained_records.remove_at(0)
	candidate.window_start_simulation_msec = candidate.ingested_through_simulation_msec
	candidate.foreground_elapsed_msec = 0
	candidate.offline_elapsed_msec = 0
	candidate.debug_elapsed_msec = 0
	candidate.next_event_sequence = 1
	candidate.slices.clear()
	candidate.settlement_events.clear()
	var candidate_validation := ReportLedgerValidator.validate(candidate)
	if not candidate_validation.ok: return _reject(ERR_CANDIDATE_INVALID, candidate_validation.details)
	return ReportLedgerSnapshotResult.applied(candidate, created_sequence)

static func _is_empty(ledger: ReportLedger) -> bool:
	return ledger.window_start_simulation_msec == ledger.ingested_through_simulation_msec \
		and ledger.foreground_elapsed_msec == 0 and ledger.offline_elapsed_msec == 0 \
		and ledger.debug_elapsed_msec == 0 and ledger.next_event_sequence == 1 \
		and ledger.slices.is_empty() and ledger.settlement_events.is_empty()

static func _record_from_live(ledger: ReportLedger, sequence: int) -> ReportWindowRecord:
	var record := ReportWindowRecord.new()
	record.record_sequence = sequence
	record.window_start_simulation_msec = ledger.window_start_simulation_msec
	record.window_end_simulation_msec = ledger.ingested_through_simulation_msec
	record.foreground_elapsed_msec = ledger.foreground_elapsed_msec
	record.offline_elapsed_msec = ledger.offline_elapsed_msec
	record.debug_elapsed_msec = ledger.debug_elapsed_msec
	for slice in ledger.slices: record.slices.append(slice.deep_clone())
	for event in ledger.settlement_events: record.settlement_events.append(event.deep_clone())
	return record

static func _reject(code: StringName, details: String) -> ReportLedgerSnapshotResult:
	return ReportLedgerSnapshotResult.rejected(code, details)

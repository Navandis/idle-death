class_name ReportLedgerReader
extends RefCounted

## Pure detached data reads. This boundary stores no source reference, cache,
## continuation state, presentation field, or lifecycle authority.

const ERR_LEDGER_REQUIRED := &"REPORT_READ_LEDGER_REQUIRED"
const ERR_LEDGER_INVALID := &"REPORT_READ_LEDGER_INVALID"
const ERR_SEQUENCE_INVALID := &"REPORT_READ_SEQUENCE_INVALID"

static func read_live_window(source_ledger: ReportLedger) -> Dictionary:
	var failure := _ledger_failure(source_ledger)
	if not failure.is_empty(): return {"ok": false, "code": failure.code, "details": failure.details, "window": null}
	return {"ok": true, "code": &"", "details": "", "window": _live_record(source_ledger)}

static func read_history(source_ledger: ReportLedger) -> Dictionary:
	var failure := _ledger_failure(source_ledger)
	if not failure.is_empty(): return {"ok": false, "code": failure.code, "details": failure.details, "records": []}
	var records: Array[ReportWindowRecord] = []
	for record in source_ledger.retained_records: records.append(record.deep_clone())
	return {"ok": true, "code": &"", "details": "", "records": records}

static func read_record(source_ledger: ReportLedger, record_sequence: int) -> Dictionary:
	var failure := _ledger_failure(source_ledger)
	if not failure.is_empty(): return {"ok": false, "found": false, "code": failure.code, "details": failure.details, "record": null}
	if record_sequence <= 0: return {"ok": false, "found": false, "code": ERR_SEQUENCE_INVALID, "details": "Record sequence must be positive.", "record": null}
	for record in source_ledger.retained_records:
		if record.record_sequence == record_sequence:
			return {"ok": true, "found": true, "code": &"", "details": "", "record": record.deep_clone()}
	return {"ok": true, "found": false, "code": &"", "details": "", "record": null}

static func _ledger_failure(ledger: ReportLedger) -> Dictionary:
	if ledger == null: return {"code": ERR_LEDGER_REQUIRED, "details": "Source ledger is required."}
	var validation := ReportLedgerValidator.validate(ledger)
	if not validation.ok: return {"code": ERR_LEDGER_INVALID, "details": validation.details}
	return {}

static func _live_record(ledger: ReportLedger) -> ReportWindowRecord:
	var record := ReportWindowRecord.new()
	record.window_start_simulation_msec = ledger.window_start_simulation_msec
	record.window_end_simulation_msec = ledger.ingested_through_simulation_msec
	record.foreground_elapsed_msec = ledger.foreground_elapsed_msec
	record.offline_elapsed_msec = ledger.offline_elapsed_msec
	record.debug_elapsed_msec = ledger.debug_elapsed_msec
	for slice in ledger.slices: record.slices.append(slice.deep_clone())
	for event in ledger.settlement_events: record.settlement_events.append(event.deep_clone())
	return record

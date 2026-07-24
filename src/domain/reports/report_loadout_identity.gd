class_name ReportLoadoutIdentity
extends RefCounted

## Immutable identity of the components that produced one report slice.
##
## This value owns only canonical IDs and the selected Retinue order. It does
## not own content definitions, rates, ETAs, production, or presentation text.
## The array is detached at construction and whenever it is exposed so report
## history cannot alias a mutable assignment record.

var _form_id: StringName
var _writ_id: StringName
var _ordered_retinue_ids: Array[StringName] = []

var form_id: StringName:
	get:
		return _form_id

var writ_id: StringName:
	get:
		return _writ_id

var ordered_retinue_ids: Array[StringName]:
	get:
		return _ordered_retinue_ids.duplicate()

func _init(form_value: StringName = &"", writ_value: StringName = &"", retinue_values: Array[StringName] = []) -> void:
	_form_id = form_value
	_writ_id = writ_value
	_ordered_retinue_ids.assign(retinue_values)

func deep_clone() -> ReportLoadoutIdentity:
	return ReportLoadoutIdentity.new(form_id, writ_id, ordered_retinue_ids)

func identity_key() -> String:
	return "%s|%s|%s" % [str(form_id), str(writ_id), ",".join(_retinue_strings())]

func value_equals(other: ReportLoadoutIdentity) -> bool:
	return other != null and form_id == other.form_id and writ_id == other.writ_id and ordered_retinue_ids == other.ordered_retinue_ids

func _retinue_strings() -> Array[String]:
	var values: Array[String] = []
	for retinue_id in ordered_retinue_ids:
		values.append(str(retinue_id))
	return values

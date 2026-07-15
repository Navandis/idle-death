class_name GuaranteeDefinition
extends ContentDefinitionBase

## Typed M03 GuaranteeDefinition authored Resource.
##
## M03 declares deterministic guarantee policy data only. Later runtime systems
## will evaluate completion state; the registry derives a content-only preview so
## tests and traces prove source references rather than duplicated floor values.

@export_enum("FIXED_ITEM_FLOOR", "DERIVED_COST_FLOOR") var policy: String = "FIXED_ITEM_FLOOR"
@export var item_id: String = ""
@export var minimum_amount: int = 0
@export var source_definition_ids: Array[String] = []
@export var derived_policy_id: String = ""
@export var buffer_multiplier: float = 1.0

class_name GuaranteeDefinition
extends ContentDefinitionBase

## Typed M03 GuaranteeDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export_enum("FIXED_ITEM_FLOOR", "DERIVED_COST_FLOOR") var policy: String = "FIXED_ITEM_FLOOR"
@export var item_id: String = ""
@export var floor_quantity: int = 0
@export var source_cost_ids: Array[String] = []

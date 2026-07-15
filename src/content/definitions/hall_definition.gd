class_name HallDefinition
extends ContentDefinitionBase

## Typed M03 HallDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var restoration_costs: Array[ItemAmountDefinition] = []
@export var unlocks_feature_id: String = ""

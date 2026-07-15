class_name RecipeDefinition
extends ContentDefinitionBase

## Typed M03 RecipeDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var hall_id: String = ""
@export var input: ItemAmountDefinition
@export var output: ItemAmountDefinition
@export var duration_msec: int = 0
@export var default_target_quantity: int = 0

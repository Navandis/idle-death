class_name RetinueDefinition
extends ContentDefinitionBase

## Typed M03 RetinueDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var required_items: Array[ItemAmountDefinition] = []
@export var support_item_id: String = ""
@export var support_period_msec: int = 300000
@export var reduced_support_floor: float = 0.5
@export var slot_categories: Array[String] = []
@export var modifiers: Array[ModifierDefinition] = []

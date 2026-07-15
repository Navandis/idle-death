class_name ResonanceDefinition
extends ContentDefinitionBase

## Typed M03 ResonanceDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var trigger_milestone_id: String = ""
@export var rewards: Array[ItemAmountDefinition] = []
@export var effects: Array[ProgressionEffectDefinition] = []

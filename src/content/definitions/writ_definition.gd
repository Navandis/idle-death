class_name WritDefinition
extends ContentDefinitionBase

## Typed M03 WritDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var transition_milestone_id: String = ""
@export var transition_to_writ_id: String = ""
@export var effects: Array[ProgressionEffectDefinition] = []

class_name RecollectionDefinition
extends ContentDefinitionBase

## Typed M03 RecollectionDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var costs: Array[ItemAmountDefinition] = []
@export var prerequisite_ids: Array[String] = []
@export var repeatable: bool = false
@export var effects: Array[ProgressionEffectDefinition] = []
@export var modifiers: Array[ModifierDefinition] = []

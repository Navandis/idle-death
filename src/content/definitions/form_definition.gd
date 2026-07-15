class_name FormDefinition
extends ContentDefinitionBase

## Typed M03 FormDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var base_returned_souls_rate: RateDefinition
@export var active_mastery_rate: RateDefinition
@export var cycle_duration_msec: int = 60000
@export var traits: Array[TraitDefinition] = []
@export var slot_affinities: Array[String] = []
@export var awakening_costs: Array[ItemAmountDefinition] = []

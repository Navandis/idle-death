class_name MilestoneDefinition
extends ContentDefinitionBase

## Typed M03 MilestoneDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export_enum("REAPING_OUTPUT", "REGIONAL_OUTPUT", "SETTLEMENT") var counter_kind: String = "REAPING_OUTPUT"
@export var subject_id: String = ""
@export var target_count: int = 0
@export var prerequisite_ids: Array[String] = []
@export var guarantee_ids: Array[String] = []
@export var resonance_id: String = ""
@export var effects: Array[ProgressionEffectDefinition] = []

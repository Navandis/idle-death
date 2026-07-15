class_name ThresholdDefinition
extends ContentDefinitionBase

## Typed M03 ThresholdDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var tags: Array[String] = []
@export var standing_backlog: int = 0
@export var settled_multiplier: float = 0.25
@export var channel_ids: Array[String] = []
@export_enum("UNKNOWN", "IDENTIFIED", "CHARTED") var discovery_state: String = "UNKNOWN"

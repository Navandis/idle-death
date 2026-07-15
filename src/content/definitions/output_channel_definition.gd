class_name OutputChannelDefinition
extends ContentDefinitionBase

## Typed M03 OutputChannelDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var source_threshold_id: String = ""
@export var output_item_id: String = ""
@export_enum("RESOURCE", "STORE", "WHOLE_ITEM") var output_kind: String = "RESOURCE"
@export var rate: RateDefinition
@export var settled_multiplier: float = 0.25
@export var progression_required: bool = false
@export var starts_hidden: bool = false
@export var requires_progress_display: bool = false
@export var identification_cycles_base: int = 0
@export var identification_cycles_scribe: int = 0
@export var charting_cycles_base: int = 0

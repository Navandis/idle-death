class_name OutputChannelDefinition
extends ContentDefinitionBase

## Typed M03 OutputChannelDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.
## Discovery fields describe presentation disclosure only; unknown channels still
## produce and bank output through later simulation systems.

@export var source_threshold_id: String = ""
@export var output_item_id: String = ""
@export_enum("RESOURCE", "STORE", "WHOLE_ITEM") var output_kind: String = "RESOURCE"
@export var rate: RateDefinition
@export var settled_multiplier: float = 0.25
@export var progression_required: bool = false
@export_enum("UNKNOWN", "IDENTIFIED", "CHARTED") var initial_discovery_state: String = "UNKNOWN"
@export_enum("NONE", "COMMON", "UNCOMMON") var frequency_tier: String = "NONE"
@export var identified_frequency_label: String = ""
@export var frequency_localization_key: String = ""
@export var show_acquisition_progress: bool = false
@export var identification_cycles_base: int = 0
@export var identification_cycles_scribe: int = 0
@export var charting_cycles_base: int = 0

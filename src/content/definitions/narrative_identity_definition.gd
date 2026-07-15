class_name NarrativeIdentityDefinition
extends ContentDefinitionBase

## Typed M03 NarrativeIdentityDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export_enum("CHARACTER", "DIALOGUE") var narrative_kind: String = "CHARACTER"
@export var presentation_only: bool = true

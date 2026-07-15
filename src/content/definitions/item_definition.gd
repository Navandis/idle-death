class_name ItemDefinition
extends ContentDefinitionBase

## Typed M03 ItemDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export_enum("RESOURCE", "STORE", "CALLING_SOUL", "FORM_SOUL") var item_kind: String = "RESOURCE"
@export var whole_units_only: bool = true

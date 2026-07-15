class_name TutorialStepDefinition
extends ContentDefinitionBase

## Typed M03 TutorialStepDefinition authored Resource.
##
## Fields in this class are definition data only. ContentRegistry validates and
## copies them into normalized runtime records before gameplay can read them.

@export var sequence_index: int = 0
@export var presentation_event_id: String = ""
@export var presentation_only: bool = true

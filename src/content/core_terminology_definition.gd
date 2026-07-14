class_name CoreTerminologyDefinition
extends Resource

## Central editable player-facing terminology catalog.
##
## Stable TERM_ keys are mechanical lookup identities. Fallback names are mutable
## presentation text and must never become save keys, logic keys, or canonical
## prefixes. The registry copies terms into immutable normalized data at load.

@export var id: String = "TERM_CATALOG_CORE"
@export var terms: Dictionary = {}

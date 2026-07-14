class_name ContentDefinition
extends Resource

## Typed authored-content record for one stable Death Idle definition.
##
## The record owns immutable designer-authored prototype data only: canonical ID,
## definition kind, editable fallback text, optional localization keys, references,
## rates, modifiers, effects, and validation metadata. It does not own mutable
## player state, simulation progress, inventory, or save data. ContentRegistry
## copies this Resource into normalized dictionaries before gameplay can read it
## so later Inspector edits cannot mutate authoritative runtime data.

@export var id: String = ""
@export var kind: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var localization_key: String = ""
@export var data: Dictionary = {}

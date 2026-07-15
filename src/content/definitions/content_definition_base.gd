class_name ContentDefinitionBase
extends Resource

## Shared typed authoring base for named M03 content definitions.
##
## This Resource owns only immutable authored definition metadata: stable
## canonical identity, editable fallback text, optional localization key, enabled
## flag, and reviewer notes. Mutable player state, simulation progress, save data,
## and editor UI state are explicitly not owned here. Family-specific subclasses
## expose typed fields so designers do not edit arbitrary dictionaries.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var localization_key: String = ""
@export var enabled: bool = true
@export_multiline var notes: String = ""

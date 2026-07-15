class_name TraitDefinition
extends Resource
## Inline stable Form Trait identity with editable presentation text.
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var localization_key: String = ""
@export var modifiers: Array[ModifierDefinition] = []

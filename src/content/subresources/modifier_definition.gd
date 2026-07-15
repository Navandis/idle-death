class_name ModifierDefinition
extends Resource
## Finite, non-executable authored modifier token with typed condition operands.
@export var metric: String = ""
@export var operation: String = ""
@export var scope: String = ""
@export var condition: String = "ALWAYS"
@export var condition_values: Array[String] = []
@export var value: float = 0.0

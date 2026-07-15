class_name ProgressionEffectDefinition
extends Resource
## Finite, non-executable progression effect declaration. M03 validates only.
@export var id: String = ""
@export var kind: String = ""
@export var item_amounts: Array[ItemAmountDefinition] = []
@export var target_ids: Array[String] = []
@export var quantity: int = 0

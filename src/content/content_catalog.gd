class_name ContentCatalog
extends Resource

## Explicit typed root Resource for M03 production content.
##
## Each exported group owns one definition family for Inspector clarity and type
## safety. The catalog is not mutable gameplay state and performs no directory
## scanning; ContentRegistry validates these explicit references into immutable
## runtime lookup records.

@export var content_revision: String = "prototype-content-r1"
@export var compatible_save_revisions: Array[String] = ["prototype-content-r1", "prototype-m02"]
@export var terminology: CoreTerminologyDefinition
@export var items: Array[ItemDefinition] = []
@export var forms: Array[FormDefinition] = []
@export var thresholds: Array[ThresholdDefinition] = []
@export var output_channels: Array[OutputChannelDefinition] = []
@export var writs: Array[WritDefinition] = []
@export var retinues: Array[RetinueDefinition] = []
@export var halls: Array[HallDefinition] = []
@export var recipes: Array[RecipeDefinition] = []
@export var recollections: Array[RecollectionDefinition] = []
@export var milestones: Array[MilestoneDefinition] = []
@export var guarantees: Array[GuaranteeDefinition] = []
@export var resonances: Array[ResonanceDefinition] = []
@export var tutorial_steps: Array[TutorialStepDefinition] = []
@export var narrative_identities: Array[NarrativeIdentityDefinition] = []

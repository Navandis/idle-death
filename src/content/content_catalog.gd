class_name ContentCatalog
extends Resource

## Explicit root Resource for Death Idle prototype content.
##
## This catalog owns the authored production definition list and revision policy.
## It deliberately references Resources explicitly instead of scanning folders so
## filenames, import order, and display names cannot become gameplay authority.
## Persistence receives revision strings from callers but does not import this
## class; ContentRegistry performs content compatibility checks after schema load.

@export var content_revision: String = "prototype-content-r1"
@export var compatible_save_revisions: Array[String] = ["prototype-content-r1", "prototype-m02"]
@export var terminology: CoreTerminologyDefinition
@export var definitions: Array[ContentDefinition] = []

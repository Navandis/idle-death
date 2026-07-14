class_name SaveFileSet
extends RefCounted

## Path contract for one prototype save file set.
##
## Production defaults live under user://saves/, while tests and traces inject an
## isolated root.  The deterministic suspect path uses revision/counter labels,
## not wall-clock values or file timestamps.

var primary_path: String
var temporary_path: String
var backup_path: String
var suspect_prefix: String

func _init(root: String = "user://saves", basename: String = "death_idle_m02") -> void:
	primary_path = root.path_join(basename + ".json")
	temporary_path = root.path_join(basename + ".tmp")
	backup_path = root.path_join(basename + ".bak.json")
	suspect_prefix = root.path_join(basename + ".suspect")

func suspect_path(revision: int, counter: int) -> String:
	return "%s.rev%s.%s.json" % [suspect_prefix, revision, counter]

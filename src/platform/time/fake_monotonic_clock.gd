class_name FakeMonotonicClock
extends MonotonicClock

## Test-only monotonic clock controlled explicitly by fixtures.

var current_msec: int = 0

func _init(initial_msec: int = 0) -> void:
	current_msec = initial_msec

func now_msec() -> int:
	return current_msec

func set_now_msec(value_msec: int) -> void:
	current_msec = value_msec

func advance_msec(elapsed_msec: int) -> void:
	current_msec += elapsed_msec

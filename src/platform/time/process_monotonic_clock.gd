class_name ProcessMonotonicClock
extends MonotonicClock

## Production foreground monotonic-clock adapter.
##
## This is the only M01 source file allowed to call Godot's process-monotonic
## clock.  It reports milliseconds since engine start and never reads local wall
## time, UTC calendar time, timezone, or file timestamps.

func now_msec() -> int:
	return Time.get_ticks_msec()

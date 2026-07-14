class_name MonotonicClock
extends RefCounted

## Project-owned monotonic foreground clock contract.
##
## Domain and simulation code should receive elapsed milliseconds, not read this
## adapter directly.  Implementations must be process-monotonic and must not use
## calendar, timezone, file timestamp, registry, or trusted-time APIs.

func now_msec() -> int:
	push_error("MonotonicClock.now_msec must be implemented by a concrete adapter.")
	return 0

class_name TrustedTimeProvider
extends RefCounted

## Contract for approved external trusted-time sources.
## M01 provides only this interface and a fake provider; M06 owns any Steam API
## bridge and must keep wrapper details outside domain state.

func sample() -> TrustedTimeSample:
	return TrustedTimeSample.unavailable("", "TIME_PROVIDER_NOT_IMPLEMENTED")

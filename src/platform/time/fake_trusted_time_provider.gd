class_name FakeTrustedTimeProvider
extends TrustedTimeProvider

## Queue-based trusted-time provider for deterministic headless tests.

var samples: Array[TrustedTimeSample] = []

func enqueue(sample_value: TrustedTimeSample) -> void:
	samples.append(sample_value)

func sample() -> TrustedTimeSample:
	if samples.is_empty():
		return TrustedTimeSample.unavailable("FAKE", TrustedTimeSample.DIAG_UNAVAILABLE)
	return samples.pop_front()

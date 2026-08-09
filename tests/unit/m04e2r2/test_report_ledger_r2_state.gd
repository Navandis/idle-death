extends GutTest

func test_continuation_and_record_clone_equality_cover_owned_children() -> void:
	var channel := ReportChannelContinuation.new()
	channel.channel_id = &"C"
	channel.output_item_id = &"SOUL"
	channel.rate_period_msec = 1000
	var continuation := ReportThresholdContinuation.new()
	continuation.threshold_id = &"T"
	continuation.latest_assignment_revision = 1
	continuation.form_id = &"F"
	continuation.writ_id = &"W"
	continuation.lifecycle_state = &"OVERDUE"
	continuation.remaining_backlog = 1
	continuation.channels.append(channel)
	var copy := continuation.deep_clone()
	assert_true(copy.value_equals(continuation), "continuation clone is equal")
	copy.channels[0].rate_period_msec = 999
	assert_false(copy.value_equals(continuation), "channel endpoint participates in equality")
	assert_eq(continuation.channels[0].rate_period_msec, 1000, "channel clone is detached")

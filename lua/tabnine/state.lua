local uv = vim.uv or vim.loop

return {
	requests_counter = 0,
	completions_cache = nil,
	rendered_completion = nil,
	cancel_completion = nil,
	debounce_timer = uv.new_timer(),
	debounce_ms = 0,
	active = nil,
}

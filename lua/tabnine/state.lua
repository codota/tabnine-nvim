local uv = vim.loop

return {
	requests_counter = 0,
	completions_cache = nil,
	rendered_completion = nil,
	completion_timer = uv.new_timer(),
	debounce_timer = uv.new_timer(),
	debounce_ms = 0,
}

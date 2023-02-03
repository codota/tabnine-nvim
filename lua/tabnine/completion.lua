local M = {}
local api = vim.api
local fn = vim.fn
local state = require("tabnine.state")
local consts = require("tabnine.consts")
local utils = require("tabnine.utils")
local tabnine_binary = require("tabnine.binary")
local config = require("tabnine.config")

local function valid_response(response)
	return response and #response.results > 1 and #response.results[1].new_prefix > 1
end

function M.accept()
	M.clear()
	local lines = utils.str_to_lines(state.rendered_completion)

	if utils.starts_with(state.rendered_completion, "\n") then
		api.nvim_buf_set_lines(0, fn.line("."), fn.line("."), false, lines)
		api.nvim_win_set_cursor(0, {
			fn.line(".") + #lines,
			fn.col(".") + #lines[#lines],
		})
		return
	end

	api.nvim_buf_set_text(0, fn.line(".") - 1, fn.col(".") - 1, fn.line(".") - 1, fn.col(".") - 1, lines)
	api.nvim_win_set_cursor(0, {
		fn.line("."),
		fn.col(".") + #lines[#lines],
	})
end

function M.clear()
	state.completion_timer:stop()
	state.debounce_timer:stop()
	api.nvim_buf_clear_namespace(0, consts.tabnine_namespace, 0, -1)
end

function M.should_complete()
	return not vim.tbl_contains(config.get_config().execlude_filetypes, vim.bo.filetype)
		and consts.valid_end_of_line_regex:match_str(utils.end_of_line())
end

function M.complete()
	local changedtick = vim.b.changedtick
	local before_table = api.nvim_buf_get_text(0, 0, 0, fn.line(".") - 1, fn.col(".") - 1, {})
	local before = table.concat(before_table, "\n")

	local after_table =
		api.nvim_buf_get_text(0, fn.line(".") - 1, fn.col(".") - 1, fn.line("$") - 1, fn.col("$,$") - 1, {})
	local after = table.concat(after_table, "\n")

	tabnine_binary:request({
		Autocomplete = {
			before = before,
			after = after,
			filename = fn.expand("%:t"),
			region_includes_beginning = true,
			region_includes_end = false,
			max_num_results = 1,
			correlation_id = state.requests_counter,
		},
	}, function(response)
		M.clear()
		if not valid_response(response) then
			state.completions_cache = nil
			return
		end

		if
			state.completions_cache
			and utils.ends_with(state.completions_cache.results[1].new_prefix, response.results[1].new_prefix)
		then
			M.render(response.results[1].new_prefix, response.old_prefix, changedtick)
			return
		end

		state.completions_cache = response
		state.debounce_timer:start(
			config.get_config().debounce_ms,
			0,
			vim.schedule_wrap(function()
				M.render(response.results[1].new_prefix, response.old_prefix, changedtick)
			end)
		)
	end)
end

function M.render(completion, old_prefix, changedtick)
	if not (vim.b.changedtick == changedtick) then
		return
	end

	local lines = utils.str_to_lines(completion)

	if utils.starts_with(completion, "\n") then
		local other_lines = vim.tbl_map(function(line)
			return { { line, consts.tabnine_hl_group } }
		end, lines)

		api.nvim_buf_set_extmark(0, consts.tabnine_namespace, fn.line(".") - 1, fn.col(".") - 1, {
			virt_lines = other_lines,
		})

		state.rendered_completion = completion
		return
	end

	lines[1] = lines[1]:sub(#old_prefix + 1, -1)
	lines[1] = utils.remove_matching_suffix(lines[1], utils.end_of_line())

	local first_line = { { lines[1], consts.tabnine_hl_group } }
	local other_lines = vim.tbl_map(function(line)
		return { { line, consts.tabnine_hl_group } }
	end, utils.subset(lines, 2))

	api.nvim_buf_set_extmark(0, consts.tabnine_namespace, fn.line(".") - 1, fn.col(".") - 1, {
		virt_text_win_col = fn.virtcol(".") - 1,
		virt_text = first_line,
		virt_lines = other_lines,
	})

	state.rendered_completion = utils.lines_to_str(lines)
end

return M

local api = vim.api
local uv = vim.loop
local fn = vim.fn
local TabnineBinary = require("tabnine.binary")
local utils = require("tabnine.utils")
local M = {}
local plugin_version = "0.1.0"
local max_chars = 3000
local tabnine_namespace = api.nvim_create_namespace("tabnine")
local requests_counter = 0
local current_completion = nil
local service_level = nil
local tabnine_binary = TabnineBinary:new({ plugin_version = plugin_version })
local valid_end_of_line_regex = vim.regex("^\\s*[)}\\]\"'`]*\\s*[:{;,]*\\s*$")
local tabnine_hl_group = "TabnineSuggestion"

local function end_of_line()
	return api.nvim_buf_get_text(0, fn.line(".") - 1, fn.col(".") - 1, fn.line(".") - 1, fn.col("$"), {})[1]
end

local function auto_complete_response(response)
	current_completion = utils.str_to_lines(response.results[1].new_prefix)
	current_completion[1] = utils.fif(
		#response.old_prefix > 0,
		current_completion[1]:sub(#response.old_prefix + 1, -1),
		current_completion[1]
	)
	current_completion[1] = utils.remove_matching_suffix(current_completion[1], end_of_line())

	local first_line = { { current_completion[1], tabnine_hl_group } }
	local other_lines = vim.tbl_map(function(line)
		return { { line, tabnine_hl_group } }
	end, utils.subset(current_completion, 2))

	api.nvim_buf_set_extmark(0, tabnine_namespace, fn.line(".") - 1, fn.col(".") - 1, {
		virt_text_win_col = fn.virtcol(".") - 1,
		hl_mode = "combine",
		virt_text = first_line,
		virt_lines = other_lines,
	})
end

local function poll_service_level()
	local timer = uv.new_timer()
	timer:start(0, 5000, function()
		vim.schedule(function()
			tabnine_binary:request({ State = {} })
		end)
	end)
end

local function dispatch_binary_responses()
	tabnine_binary:on_response(function(response)
		if
			not utils.pumvisible()
			and response.results
			and response.results[1]
			and #response.results[1].new_prefix > 0
		then
			auto_complete_response(response)
		elseif response.service_level then
			service_level = response.service_level
		end
	end)
end

local function clear_suggestion()
	api.nvim_buf_clear_namespace(0, tabnine_namespace, 0, -1)
end

local function bind_to_document_changed(debounce_ms)
	local function auto_complete_request()
		local before_table = api.nvim_buf_get_text(0, 0, 0, fn.line(".") - 1, fn.col(".") - 1, {})
		local before = table.concat(before_table, "\n")

		tabnine_binary:request({
			Autocomplete = {
				before = before,
				after = "",
				filename = fn.expand("%:t"),
				region_includes_beginning = true,
				region_includes_end = false,
				max_num_results = 1,
				correlation_id = requests_counter,
			},
		})
	end

	local debounced_auto_complete_request = utils.debounce_trailing(function()
		if valid_end_of_line_regex:match_str(end_of_line()) then
			auto_complete_request()
		end
	end, debounce_ms, false)

	api.nvim_create_autocmd("TextChangedI", {
		pattern = "*",
		callback = function()
			clear_suggestion()
			debounced_auto_complete_request()
		end,
	})
end

local function bind_to_accept(accept_keymap)
	local function accept_suggestion()
		if current_completion then
			api.nvim_buf_set_text(
				0,
				fn.line(".") - 1,
				fn.col(".") - 1,
				fn.line(".") - 1,
				fn.col(".") - 1,
				current_completion
			)

			api.nvim_win_set_cursor(0, {
				fn.line("."),
				fn.col(".") + #current_completion[#current_completion],
			})

			current_completion = nil
		end
	end

	api.nvim_set_keymap("i", accept_keymap, "", {
		noremap = true,
		callback = function()
			clear_suggestion()
			accept_suggestion()
		end,
	})
end

local function create_user_commands()
	api.nvim_create_user_command("TabnineHub", function()
		tabnine_binary:request({ Configuration = {} })
	end, {})
end

local function create_auto_commands(config)
	api.nvim_create_autocmd("ModeChanged,CursorChangedI", { pattern = "*", callback = clear_suggestion })

	if config.disable_auto_comment then
		api.nvim_create_autocmd("FileType", {
			pattern = "*",
			command = "setlocal formatoptions-=c formatoptions-=r formatoptions-=o",
		})
	end

	api.nvim_create_autocmd("VimEnter,ColorScheme", {
		pattern = "*",
		callback = function()
			api.nvim_set_hl(0, tabnine_hl_group, {
				fg = config.suggestion_color.gui,
				ctermfg = config.suggestion_color.cterm,
			})
		end,
	})
end

function M.service_level()
	return service_level
end

function M.setup(config)
	config = vim.tbl_extend("force", {
		disable_auto_comment = false,
		accept_keymap = "<Tab>",
		debounce_ms = 300,
		suggestion_color = { gui = "#808080", cterm = 244 },
	}, config or {})

	dispatch_binary_responses()

	poll_service_level()

	bind_to_document_changed(config.debounce_ms)

	bind_to_accept(config.accept_keymap)

	create_user_commands()

	create_auto_commands(config)
end

return M

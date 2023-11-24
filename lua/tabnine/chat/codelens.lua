local chat = require("tabnine.chat")
local config = require("tabnine.config")
local consts = require("tabnine.consts")
local api = vim.api
local fn = vim.fn

local M = {}
local SYMBOL_KIND = { FUNCTION = 12, CLASS = 5, METHOD = 6 }
local current_symbols = {}
local symbol_under_cursor = nil
local cancel_lsp_request = nil

function M.should_display_codelense()
	return not vim.tbl_contains(config.get_config().exclude_filetypes, vim.bo.filetype)
end

function M.reload_symbols()
	if not vim.lsp.buf.server_ready() then return end

	local params = vim.lsp.util.make_position_params()

	if cancel_lsp_request then cancel_lsp_request() end

	cancel_lsp_request = vim.lsp.buf_request_all(0, "textDocument/documentSymbol", params, function(responses)
		current_symbols = {}
		for _, response in ipairs(responses) do
			for _, result in ipairs(response.result) do
				if result.kind == SYMBOL_KIND.FUNCTION or result.kind == SYMBOL_KIND.METHOD then
					table.insert(current_symbols, result)
				end
			end
		end
	end)
end

function M.run_under_cursor(command)
	if not symbol_under_cursor then return end
	chat.open(function()
		M.select_range({
			{
				symbol_under_cursor.range.start.line + 1,
				symbol_under_cursor.range.start.character + 1,
			},
			{
				symbol_under_cursor.range["end"].line + 1,
				symbol_under_cursor.range["end"].character + 1,
			},
		})
		chat.submit_message(command)
		chat.focus()
	end)
end

local function is_symbol_under_cursor(symbol)
	local line = fn.line(".")
	return line > symbol.range.start.line and line <= symbol.range["end"].line
end

function M.reload_codelens()
	local new_symbol_under_cursor = nil
	for _, symbol in ipairs(current_symbols) do
		if is_symbol_under_cursor(symbol) then new_symbol_under_cursor = symbol end
	end

	if new_symbol_under_cursor == symbol_under_cursor then return end

	if not new_symbol_under_cursor then
		api.nvim_buf_clear_namespace(0, consts.tabnine_codelens_namespace, 0, -1)
	elseif new_symbol_under_cursor then
		api.nvim_buf_clear_namespace(0, consts.tabnine_codelens_namespace, 0, -1)
		api.nvim_buf_set_extmark(
			0,
			consts.tabnine_codelens_namespace,
			new_symbol_under_cursor.range.start.line,
			0,
			{ virt_text = { { "{💡} tabnine", consts.tabnine_codelens_hl_group } } }
		)
	end
	symbol_under_cursor = new_symbol_under_cursor
end

function M.select_range(range)
	local start_row, start_col, end_row, end_col = range[1][1], range[1][2], range[2][1], range[2][2]

	local v_table = { charwise = "v", linewise = "V", blockwise = "<C-v>" }
	selection_mode = selection_mode or "charwise"

	-- Normalise selection_mode
	if vim.tbl_contains(vim.tbl_keys(v_table), selection_mode) then selection_mode = v_table[selection_mode] end

	-- enter visual mode if normal or operator-pending (no) mode
	-- Why? According to https://learnvimscriptthehardway.stevelosh.com/chapters/15.html
	--   If your operator-pending mapping ends with some text visually selected, Vim will operate on that text.
	--   Otherwise, Vim will operate on the text between the original cursor position and the new position.
	local mode = api.nvim_get_mode()
	if mode.mode ~= selection_mode then
		-- Call to `nvim_replace_termcodes()` is needed for sending appropriate command to enter blockwise mode
		selection_mode = vim.api.nvim_replace_termcodes(selection_mode, true, true, true)
		api.nvim_cmd({ cmd = "normal", bang = true, args = { selection_mode } }, {})
	end

	api.nvim_win_set_cursor(0, { start_row, start_col - 1 })
	vim.cmd("normal! o")
	api.nvim_win_set_cursor(0, { end_row, end_col - 1 })
end

return M

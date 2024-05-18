local chat = require("tabnine.chat")
local config = require("tabnine.config")
local consts = require("tabnine.consts")
local lsp = require("tabnine.lsp")
local state = require("tabnine.state")
local utils = require("tabnine.utils")
local api = vim.api
local fn = vim.fn

local M = {}
local current_symbols = {}
local symbol_under_cursor = nil
local cancel_lsp_request = nil
local buf_supports_symbols = nil

function M.reload_buf_supports_symbols()
	local clients = utils.buf_get_clients()

	for _, client in ipairs(clients) do
		if client.server_capabilities.documentSymbolProvider then
			buf_supports_symbols = true
			return
		end
	end

	buf_supports_symbols = false
end

function M.should_display()
	return config.get_config().codelens_enabled
		and state.active
		and #utils.buf_get_clients() > 0
		and not vim.tbl_contains(config.get_config().exclude_filetypes, vim.bo.filetype)
		and buf_supports_symbols
end

function M.collect_symbols(on_collect)
	if cancel_lsp_request then cancel_lsp_request() end

	cancel_lsp_request = lsp.get_document_symbols("", function(symbols)
		current_symbols = symbols
		on_collect()
	end)
end

function M.run_under_cursor(command)
	if not symbol_under_cursor then return end
	chat.open(function()
		utils.select_range({
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
	return symbol.range and line > symbol.range.start.line and line <= symbol.range["end"].line + 1
end

function M.clear()
	symbol_under_cursor = nil
	api.nvim_buf_clear_namespace(0, consts.tabnine_codelens_namespace, 0, -1)
end

function M.reload()
	local new_symbol_under_cursor = nil
	for _, symbol in ipairs(current_symbols) do
		if is_symbol_under_cursor(symbol) then new_symbol_under_cursor = symbol end
	end

	if new_symbol_under_cursor == symbol_under_cursor then return end

	if not new_symbol_under_cursor then
		M.clear()
	elseif new_symbol_under_cursor then
		M.clear()
		api.nvim_buf_set_extmark(
			0,
			consts.tabnine_codelens_namespace,
			new_symbol_under_cursor.range.start.line,
			0,
			{ virt_text = { { "⌬ tabnine {}", consts.tabnine_codelens_hl_group } } }
		)
	end
	symbol_under_cursor = new_symbol_under_cursor
end

return M

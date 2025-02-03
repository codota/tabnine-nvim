local api = vim.api
local chat = require("tabnine.chat")
local codelens = require("tabnine.chat.codelens")
local utils = require("tabnine.utils")
local workspace = require("tabnine.workspace")
local M = {}

function M.setup()
	api.nvim_create_autocmd("VimLeavePre", {
		pattern = "*",
		callback = function()
			if chat.is_open() then chat.close() end
		end,
	})

	api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" }, {
		pattern = "*",
		callback = utils.debounce(function()
			if codelens.should_display() then
				pcall(codelens.collect_symbols, codelens.reload)
			else
				codelens.clear()
			end
		end, 100),
	})

	api.nvim_create_autocmd({ "BufEnter" }, {
		pattern = "*",
		callback = codelens.reload_buf_supports_symbols,
	})

	api.nvim_create_autocmd({ "LspAttach" }, {
		pattern = "*",
		callback = function()
			workspace.update()
			codelens.reload_buf_supports_symbols()
		end,
	})
end

return M

local api = vim.api
local chat = require("tabnine.chat")
local codelens = require("tabnine.chat.codelens")
local M = {}

function M.setup()
	api.nvim_create_autocmd("VimLeavePre", {
		pattern = "*",
		callback = function()
			if chat.is_open() then chat.close() end
		end,
	})

	api.nvim_create_autocmd({ "CursorMoved" }, {
		pattern = "*",
		callback = function()
			if codelens.should_display_codelense() then codelens.reload_codelens() end
		end,
	})

	api.nvim_create_autocmd({ "TextChanged", "BufEnter" }, {
		pattern = "*",
		callback = function()
			if codelens.should_display_codelense() then pcall(codelens.reload_symbols) end
		end,
	})
end

return M

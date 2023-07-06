local api = vim.api
local chat = require("tabnine.chat")

local M = {}

function M.setup()
	api.nvim_create_autocmd("VimLeavePre", {
		pattern = "*",
		callback = function()
			if chat.is_open() then
				chat.close()
			end
		end,
	})
end

return M

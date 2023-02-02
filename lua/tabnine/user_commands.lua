local M = {}
local api = vim.api
local tabnine_binary = require("tabnine.binary")

function M.setup()
	api.nvim_create_user_command("TabnineHub", function()
		tabnine_binary:request({ Configuration = {} }, function() end)
	end, {})
end

return M

local M = {}
local api = vim.api
local tabnine_binary = require("tabnine.binary")

function M.setup()
	api.nvim_create_user_command("TabnineHub", function()
		tabnine_binary:request({ Configuration = {} }, function() end)
	end, {})

	api.nvim_create_user_command("TabnineHubUrl", function()
		tabnine_binary:request({ Configuration = { quiet = true } }, function(response)
			print(response.message)
		end)
	end, {})
end

return M

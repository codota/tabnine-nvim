local M = {}
local api = vim.api
local fn = vim.fn
local tabnine_binary = require("tabnine.binary")
local status = require("tabnine.status")

function M.setup()
	api.nvim_create_user_command("TabnineHub", function()
		tabnine_binary:request({ Configuration = {} }, function() end)
	end, {})

	api.nvim_create_user_command("TabnineHubUrl", function()
		tabnine_binary:request({ Configuration = { quiet = true } }, function(response)
			print(response.message)
		end)
	end, {})

	api.nvim_create_user_command("TabnineEnable", status.enable_tabnine, {})
	api.nvim_create_user_command("TabnineDisable", status.disable_tabnine, {})
	api.nvim_create_user_command("TabnineToggle", status.toggle_tabnine, {})
	api.nvim_create_user_command("TabnineStatus", function()
		print(status.status())
	end, {})
end

return M

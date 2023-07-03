local M = {}
local api = vim.api
local status = require("tabnine.status")
local config = require("tabnine.config")
local tabnine_binary = require("tabnine.binary")
local chat = require("tabnine.chat")

function M.setup()
	if not config.is_enterprise() then
		api.nvim_create_user_command("TabnineHub", function()
			tabnine_binary:request({ Configuration = { quiet = false } }, function() end)
		end, {})

		api.nvim_create_user_command("TabnineHubUrl", function()
			tabnine_binary:request({ Configuration = { quiet = true } }, function(response)
				print(response.message)
			end)
		end, {})
	else
		api.nvim_create_user_command("TabnineWhoAmI", function()
			tabnine_binary:request({ UserInfo = { quiet = false } }, function(response)
				print(response.email)
			end)
		end, {})
	end

	api.nvim_create_user_command("TabnineLogin", function()
		tabnine_binary:request({ Login = { dummy = true } }, function() end)
	end, {})

	api.nvim_create_user_command("TabnineLogout", function()
		tabnine_binary:request({ Logout = { dummy = true } }, function() end)
	end, {})

	api.nvim_create_user_command("TabnineEnable", status.enable_tabnine, {})
	api.nvim_create_user_command("TabnineDisable", status.disable_tabnine, {})
	api.nvim_create_user_command("TabnineToggle", status.toggle_tabnine, {})
	api.nvim_create_user_command("TabnineStatus", function()
		print(status.status())
	end, {})
end

return M

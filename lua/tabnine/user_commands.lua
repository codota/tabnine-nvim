local M = {}
local api = vim.api
local fn = vim.fn
local tabnine_binary = require("tabnine.binary")
local state = require("tabnine.state")
local utils = require("tabnine.utils")
local status = require("tabnine.status")

local DISABLED_FILE = utils.script_path() .. "/.disabled"

function M.setup()
	api.nvim_create_user_command("TabnineHub", function()
		tabnine_binary:request({ Configuration = {} }, function() end)
	end, {})

	api.nvim_create_user_command("TabnineHubUrl", function()
		tabnine_binary:request({ Configuration = { quiet = true } }, function(response)
			print(response.message)
		end)
	end, {})

	_, disabled_file_exists = pcall(fn.filereadable, DISABLED_FILE)
	state.active = disabled_file_exists == 0

	api.nvim_create_user_command("TabnineEnable", function()
		pcall(fn.delete, DISABLED_FILE)
		state.active = true
	end, {})
	api.nvim_create_user_command("TabnineDisable", function()
		pcall(fn.writefile, { "" }, DISABLED_FILE, "b")
		state.active = false
	end, {})

	api.nvim_create_user_command("TabnineStatus", function()
		print(status.status())
	end, {})
end

return M

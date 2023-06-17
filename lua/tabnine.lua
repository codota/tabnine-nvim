local config = require("tabnine.config")
local auto_commands = require("tabnine.auto_commands")
local user_commands = require("tabnine.user_commands")
local status = require("tabnine.status")
local keymaps = require("tabnine.keymaps")

local M = {}

function M.setup(o)
	config.set_config(o)

	if vim.version.lt(vim.version(), { 0, 7, 1 }) then
		local v = string.match(tostring(vim.cmd.version()), ".*\n")

		vim.notify_once("tabnine-nvim requires neovim version >0.7.1. Current version: " .. v, vim.log.levels.WARN)
		return nil
	end

	keymaps.setup()

	user_commands.setup()

	auto_commands.setup()

	status.setup()
end

return M

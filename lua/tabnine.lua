local config = require("tabnine.config")
local auto_commands = require("tabnine.auto_commands")
local user_commands = require("tabnine.user_commands")
local status = require("tabnine.status")
local keymaps = require("tabnine.keymaps")

local M = {}

function M.setup(o)
	config.set_config(o)

	local min_version = "0.7.1"
	local v = vim.version()
	if vim.version.lt(v, vim.version.parse(min_version) or {}) then
		vim.notify_once(
			string.format(
				"tabnine-nvim requires neovim version >=%s. Current version: %d.%d.%d",
				min_version,
				v.major,
				v.minor,
				v.patch
			),
			vim.log.levels.WARN
		)
		return nil
	end

	keymaps.setup()

	user_commands.setup()

	auto_commands.setup()

	status.setup()
end

return M

local auto_commands = require("tabnine.auto_commands")
local chat_setup = require("tabnine.chat.setup")
local config = require("tabnine.config")
local consts = require("tabnine.consts")
local keymaps = require("tabnine.keymaps")
local semver = require("tabnine.third_party.semver.semver")
local status = require("tabnine.status")
local user_commands = require("tabnine.user_commands")
local workspace = require("tabnine.workspace")

local M = {}

function M.setup(o)
	config.set_config(o)

	local v = vim.version()
	local cur_version = semver(v.major, v.minor, v.patch)
	local min_version = semver(consts.min_nvim_version)
	if cur_version < min_version then
		vim.notify_once(
			string.format(
				"tabnine-nvim requires neovim version >=%s. Current version: %d.%d.%d",
				consts.min_nvim_version,
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

	chat_setup.setup()

	workspace.setup()
end

return M

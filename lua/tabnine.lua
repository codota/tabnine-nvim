local config = require("tabnine.config")
local consts = require("tabnine.consts")
local semver = require("tabnine.third_party.semver.semver")
local auto_commands = require("tabnine.auto_commands")
local user_commands = require("tabnine.user_commands")
local status = require("tabnine.status")
local keymaps = require("tabnine.keymaps")
local chat_setup = require("tabnine.chat.setup")

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
end

return M

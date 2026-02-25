local auto_commands = require("tabnine.auto_commands")
local chat_setup = require("tabnine.chat.setup")
local config = require("tabnine.config")
local consts = require("tabnine.consts")
local keymaps = require("tabnine.keymaps")
local node_server = require("tabnine.node_server")
local ports = require("tabnine.ports")
local semver = require("tabnine.third_party.semver.semver")
local status = require("tabnine.status")
local tabnine_binary = require("tabnine.binary")
local user_commands = require("tabnine.user_commands")
local workspace = require("tabnine.workspace")

local M = {}

function M.setup(o)
	config.set_config(o)

	-- 1. Initialize ports (allocates node_server_port and rust_server_port)
	ports.init()

	-- 2. Start TabNine binary (receives NODE_SERVER_PORT and RUST_SERVER_PORT env vars)
	tabnine_binary:start()

	-- 3. Trigger Rust HTTP server to start by sending ChatCommunicatorAddress request
	tabnine_binary:request({
		ChatCommunicatorAddress = { kind = "Forward" },
	}, function()
		-- 4. Start node server after Rust HTTP server is ready
		node_server:ensure_running()
	end)

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

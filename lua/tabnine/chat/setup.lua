local auto_commands = require("tabnine.chat.auto_commands")
local chat = require("tabnine.chat")
local codelens = require("tabnine.chat.codelens")
local config = require("tabnine.config")
local features = require("tabnine.features")
local user_commands = require("tabnine.chat.user_commands")

local M = {}

function M.setup()
	features.if_feature_enabled({ "alpha", "plugin.feature.tabnine_chat" }, function()
		user_commands.setup()
		auto_commands.setup()
		chat.setup()
	end)

	if config.is_enterprise() then
		user_commands.setup()
		auto_commands.setup()
		chat.setup()
	end
end

return M

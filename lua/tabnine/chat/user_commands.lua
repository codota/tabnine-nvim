local M = {}
local api = vim.api
local config = require("tabnine.config")
local chat = require("tabnine.chat")

function M.setup()
	if not config.is_enterprise() then
		api.nvim_create_user_command("TabnineChat", chat.open, {})
		api.nvim_create_user_command("TabnineChatClose", chat.close, {})
		api.nvim_create_user_command("TabnineChatClear", chat.clear_conversation, {})
		api.nvim_create_user_command("TabnineChatNew", chat.new_conversation, {})
	end
end

return M

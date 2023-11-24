local M = {}
local api = vim.api
local chat = require("tabnine.chat")
local codelens = require("tabnine.chat.codelens")
local config = require("tabnine.config")

function M.setup()
	if not config.is_enterprise() then
		api.nvim_create_user_command("TabnineChat", chat.open, {})
		api.nvim_create_user_command("TabnineChatClose", chat.close, {})
		api.nvim_create_user_command("TabnineChatClear", chat.clear_conversation, {})
		api.nvim_create_user_command("TabnineChatNew", chat.new_conversation, {})
		api.nvim_create_user_command("TabnineExplain", function()
			codelens.run_under_cursor("/explain-code")
		end, {})
		api.nvim_create_user_command("TabnineGenerateTest", function()
			codelens.run_under_cursor("/generate-test-for-code")
		end, {})
	end
end

return M

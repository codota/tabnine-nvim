local M = {}
local api = vim.api
local apply = require("tabnine.apply")
local chat = require("tabnine.chat")
local codelens = require("tabnine.chat.codelens")

function M.setup()
	api.nvim_create_user_command("TabnineChat", function()
		chat.open()
	end, {})
	api.nvim_create_user_command("TabnineChatClose", chat.close, {})
	api.nvim_create_user_command("TabnineChatClear", chat.clear_conversation, {})
	api.nvim_create_user_command("TabnineChatNew", chat.new_conversation, {})
	api.nvim_create_user_command("TabnineExplain", function()
		codelens.run_under_cursor("/explain-code")
	end, {})
	api.nvim_create_user_command("TabnineTest", function()
		codelens.run_under_cursor("/generate-test-for-code")
	end, {})
	api.nvim_create_user_command("TabnineFix", function()
		codelens.run_under_cursor("/fix-code")
	end, {})
	api.nvim_create_user_command("TabnineAccept", function()
		apply.accept()
	end, {})
	api.nvim_create_user_command("TabnineReject", function()
		apply.reject()
	end, {})
end

return M

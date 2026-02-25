local M = {}
local api = vim.api
local apply = require("tabnine.chat.apply")
local chat = require("tabnine.chat")
local codelens = require("tabnine.chat.codelens")

local function deprecated(old_cmd, new_cmd, fn)
	return function()
		vim.notify(old_cmd .. " is deprecated, use " .. new_cmd .. " instead", vim.log.levels.WARN)
		fn()
	end
end

function M.setup()
	-- New TabnineAgent commands
	api.nvim_create_user_command("TabnineAgent", function()
		chat.open()
	end, {})
	api.nvim_create_user_command("TabnineAgentClose", chat.close, {})
	api.nvim_create_user_command("TabnineAgentClear", chat.clear_conversation, {})
	api.nvim_create_user_command("TabnineAgentNew", chat.new_conversation, {})

	-- Deprecated TabnineChat commands
	api.nvim_create_user_command("TabnineChat", deprecated("TabnineChat", "TabnineAgent", chat.open), {})
	api.nvim_create_user_command("TabnineChatClose", deprecated("TabnineChatClose", "TabnineAgentClose", chat.close), {})
	api.nvim_create_user_command("TabnineChatClear", deprecated("TabnineChatClear", "TabnineAgentClear", chat.clear_conversation), {})
	api.nvim_create_user_command("TabnineChatNew", deprecated("TabnineChatNew", "TabnineAgentNew", chat.new_conversation), {})
	api.nvim_create_user_command("TabnineExplain", function()
		codelens.run_under_cursor("/explain-code")
	end, {})
	api.nvim_create_user_command("TabnineTest", function()
		codelens.run_under_cursor("/generate-test-for-code")
	end, {})
	api.nvim_create_user_command("TabnineFix", function()
		codelens.run_under_cursor("/fix-code")
	end, {})
	api.nvim_create_user_command("TabnineAccept", apply.accept, {})
	api.nvim_create_user_command("TabnineReject", apply.reject, {})
end

return M

local M = {}
local completion = require("tabnine.completion")
local config = require("tabnine.config")
local state = require("tabnine.state")

function M.setup()
	local accept_keymap = config.get_config().accept_keymap
	local dismiss_keymap = config.get_config().dismiss_keymap
	vim.keymap.set("i", accept_keymap, function()
		if not state.completions_cache then return accept_keymap end
		vim.schedule(completion.accept)
	end, { expr = true })

	vim.keymap.set("i", dismiss_keymap, function()
		if not state.completions_cache then return dismiss_keymap end
		vim.schedule(function()
			completion.clear()
			state.completions_cache = nil
		end)
	end, { expr = true })
end

return M

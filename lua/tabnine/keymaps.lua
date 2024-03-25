local M = {}
local completion = require("tabnine.completion")
local config = require("tabnine.config")
local state = require("tabnine.state")

---@return boolean
function M.has_suggestion()
	return state.active == true and state.completions_cache ~= nil
end
M.accept_suggestion = vim.schedule_wrap(function()
	if not M.has_suggestion() then return end
	return completion.accept()
end)
M.dismiss_suggestion = vim.schedule_wrap(function()
	if not M.has_suggestion() then return end
	completion.clear()
	state.completions_cache = nil
end)

function M.setup()
	local accept_keymap = config.get_config().accept_keymap
	local dismiss_keymap = config.get_config().dismiss_keymap
	if accept_keymap then -- allow setting to `false` to disable
		vim.keymap.set("i", accept_keymap, function()
			if not M.has_suggestion() then return accept_keymap end
			return M.accept_suggestion()
		end, { expr = true })
	end

	if dismiss_keymap then -- allow setting to `false` to disable
		vim.keymap.set("i", dismiss_keymap, function()
			if not M.has_suggestion() then return dismiss_keymap end
			return M.dismiss_suggestion()
		end, { expr = true })
	end
end

return M

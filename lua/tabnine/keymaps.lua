local M = {}
local api = vim.api
local fn = vim.fn
local state = require("tabnine.state")
local config = require("tabnine.config")
local completion = require("tabnine.completion")

local function create_keymap(mode, lhs, rhs, opts)
	-- If vim.keymap is supplied then use it, else use vim.api.nvim_set_keymap
	if (vim.keymap and vim.keymap.set) then
		vim.keymap.set(mode, lhs, rhs, opts)
		return;
	end
	mode = type(mode) == 'string' and { mode } or mode
	for _, m in ipairs(mode) do
		vim.api.nvim_set_keymap(m, lhs, rhs, opts)
	end
end

function M.setup()
	local accept_keymap = config.get_config().accept_keymap
	local dismiss_keymap = config.get_config().dismiss_keymap
	create_keymap("i", accept_keymap, function()
		if not state.completions_cache then
			return accept_keymap
		end
		vim.schedule(completion.accept)
	end, { expr = true })

	create_keymap("i", dismiss_keymap, function()
		if not state.completions_cache then
			return dismiss_keymap
		end
		vim.schedule(function()
			completion.clear()
			state.completions_cache = nil
		end)
	end, { expr = true })
end

return M

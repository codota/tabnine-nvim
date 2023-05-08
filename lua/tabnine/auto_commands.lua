local api = vim.api
local consts = require("tabnine.consts")
local state = require("tabnine.state")
local completion = require("tabnine.completion")
local config = require("tabnine.config")

local M = {}

function M.setup()
	api.nvim_create_autocmd("InsertLeave", { pattern = "*", callback = completion.clear })

	if config.get_config().disable_auto_comment then
		api.nvim_create_autocmd("FileType", {
			pattern = "*",
			command = "setlocal formatoptions-=c formatoptions-=r formatoptions-=o",
		})
	end

	api.nvim_create_autocmd("VimEnter,ColorScheme", {
		pattern = "*",
		callback = function()
			if config.get_config().suggestion_color == nil then
				vim.api.nvim_command(
					"highlight default link TabnineSuggestion " .. config.get_config().suggestion_hl_group
				)
			else
				api.nvim_set_hl(0, consts.tabnine_hl_group, {
					fg = config.get_config().suggestion_color.gui,
					ctermfg = config.get_config().suggestion_color.cterm,
				})
			end
		end,
	})

	api.nvim_create_autocmd("CursorMovedI", {
		pattern = "*",
		callback = function()
			if completion.should_complete() then
				completion.complete()
			else
				completion.clear()
				state.completions_cache = nil
			end
		end,
	})
end

return M

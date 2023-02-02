local api = vim.api
local consts = require("tabnine.consts")
local state = require("tabnine.state")
local completion = require("tabnine.completion")
local config = require("tabnine.config")

local M = {}

function M.setup()
	api.nvim_create_autocmd("ModeChanged", { pattern = "*", callback = completion.clear })

	if config.get_config().disable_auto_comment then
		api.nvim_create_autocmd("FileType", {
			pattern = "*",
			command = "setlocal formatoptions-=c formatoptions-=r formatoptions-=o",
		})
	end

	api.nvim_create_autocmd("VimEnter,ColorScheme", {
		pattern = "*",
		callback = function()
			api.nvim_set_hl(0, consts.tabnine_hl_group, {
				fg = config.get_config().suggestion_color.gui,
				ctermfg = config.get_config().suggestion_color.cterm,
			})
		end,
	})

	api.nvim_create_autocmd("CursorMovedI", {
		pattern = "*",
		callback = function()
			state.completion_timer:stop()
			state.debounce_timer:stop()
			if completion.should_complete() then
				state.completion_timer:start(0, 0, vim.schedule_wrap(completion.complete))
			end
		end,
	})
end

return M

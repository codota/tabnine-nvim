local api = vim.api
local consts = require("tabnine.consts")
local state = require("tabnine.state")
local completion = require("tabnine.completion")
local config = require("tabnine.config")
local chat = require("tabnine.chat")

local M = {}

function M.setup()
	-- CursorMoved is only triggered in Normal or Visual - see ':h CursorMoved'
	api.nvim_create_autocmd({ "InsertLeave", "CursorMoved" }, { pattern = "*", callback = completion.clear })

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
			if completion.should_complete() then
				completion.complete()
			else
				completion.clear()
				state.completions_cache = nil
			end
		end,
	})
	api.nvim_create_autocmd("VimLeavePre", {
		pattern = "*",
		callback = function()
			if chat.is_open() then
				chat.close()
			end
		end,
	})
end

return M

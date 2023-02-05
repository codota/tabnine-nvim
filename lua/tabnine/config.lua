local M = {}
local config = {}

function M.set_config(o)
	config = vim.tbl_extend("force", {
		disable_auto_comment = false,
		accept_keymap = "<Tab>",
		dismiss_keymap = "<C-]>",
		debounce_ms = 800,
		suggestion_color = { gui = "#808080", cterm = 244 },
		execlude_filetypes = { "TelescopePrompt" },
	}, o or {})
end

function M.get_config()
	return config
end

return M

local M = {}
local config = {}

function M.set_config(o)
	config = vim.tbl_extend("force", {
		disable_auto_comment = false,
		accept_keymap = "<Tab>",
		dismiss_keymap = "<C-]>",
		debounce_ms = 800,
		suggestion_hl_group = "Comment",
		suggestion_color = nil,
		exclude_filetypes = { "TelescopePrompt" },
		log_file_path = nil,
	}, o or {})
end

function M.get_config()
	return config
end

return M

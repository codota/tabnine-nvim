local M = {}
local config = {}

function M.set_config(o)
	config = vim.tbl_extend("force", {
		disable_auto_comment = false,
		accept_keymap = "<Tab>",
		dismiss_keymap = "<C-]>",
		debounce_ms = 800,
		suggestion_color = { gui = "#808080", cterm = 244 },
		exclude_filetypes = { "TelescopePrompt", "NvimTree" },
		log_file_path = nil,
		tabnine_enterprise_host = nil,
	}, o or {})
end

function M.get_config()
	return config
end

function M.is_enterprise()
	return config.tabnine_enterprise_host ~= nil
end

return M

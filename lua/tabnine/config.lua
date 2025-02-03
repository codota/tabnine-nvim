local M = {}
local config = {}

function M.set_config(o)
	config = vim.tbl_deep_extend("force", {
		disable_auto_comment = false,
		accept_keymap = "<Tab>",
		dismiss_keymap = "<C-]>",
		debounce_ms = 800,
		suggestion_color = { gui = "#808080", cterm = 244 },
		codelens_color = { gui = "#808080", cterm = 244 },
		codelens_enabled = true,
		exclude_filetypes = { "TelescopePrompt", "NvimTree" },
		log_file_path = nil,
		tabnine_enterprise_host = nil,
		ignore_certificate_errors = false,
		workspace_folders = {
			paths = {},
			lsp = true,
			get_paths = nil,
		},
	}, o or {})
end

function M.get_config()
	return config
end

function M.is_enterprise()
	return config.tabnine_enterprise_host ~= nil
end

return M

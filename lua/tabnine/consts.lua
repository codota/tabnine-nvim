local api = vim.api

return {
	plugin_version = "1.7.0",
	min_nvim_version = "0.7.1",
	max_chars = 3000,
	tabnine_hl_group = "TabnineSuggestion",
	tabnine_codelens_hl_group = "TabnineCodeLens",
	tabnine_namespace = api.nvim_create_namespace("tabnine"),
	tabnine_codelens_namespace = api.nvim_create_namespace("tabnine_codelens"),
	valid_end_of_line_regex = vim.regex("^\\s*[)}\\]\"'`]*\\s*[:{;,]*\\s*$"),
}

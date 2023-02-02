local api = vim.api

return {
	plugin_version = "0.4.0",
	max_chars = 3000,
	tabnine_hl_group = "TabnineSuggestion",
	tabnine_namespace = api.nvim_create_namespace("tabnine"),
	valid_end_of_line_regex = vim.regex("^\\s*[)}\\]\"'`]*\\s*[:{;,]*\\s*$"),
}

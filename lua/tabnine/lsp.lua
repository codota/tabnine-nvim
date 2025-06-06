local utils = require("tabnine.utils")
local M = {}

M.SYMBOL_KIND = { FILE = 0, FUNCTION = 12, CLASS = 5, METHOD = 6 }

local function is_not_source(symbol_path)
	local dirs = { "node_modules", "dist", "build", "target", "out" }
	for i, dir in ipairs(dirs) do
		if string.sub(symbol_path, 1, string.len(dir)) == dir then return true end
	end
	return false
end

local function flatten_symbols(symbols, result)
	result = result or {}

	for _, symbol in ipairs(symbols) do
		table.insert(result, symbol)

		if symbol.children then flatten_symbols(symbol.children, result) end
	end

	return result
end

local EXCLUDE_FILE_PATHS = {
	"node_modules/",
	"\\.git/",
	"\\.vscode",
	"dist/",
	"\\.log$",
	"\\.tmp$",
	"\\.DS_Store$",
	"__pycache__/",
	"\\.class$",
}

local function get_files_as_workspace_symbols(query, max_num_of_results)
	local files = {}
	for _, relative_path in ipairs(vim.fn.glob("**/" .. query, true, true)) do
		for _, exclude_pattern in ipairs(EXCLUDE_FILE_PATHS) do
			if relative_path:match(exclude_pattern) then goto glob_loop end
		end
		table.insert(files, {
			kind = M.SYMBOL_KIND.FILE,
			relativePath = relative_path,
			name = vim.fn.fnamemodify(relative_path, ":t"),
			containerName = "",
			location = {
				uri = vim.fn.getcwd() .. "/" .. relative_path,
				range = { start = { line = 0, character = 0 }, ["end"] = { line = -1, character = -1 } },
			},
		})
		::glob_loop::
	end
	return files
end

function M.get_workspace_symbols(query, callback)
	local params = { query = query }
	local files_symbols = get_files_as_workspace_symbols(query)
	return vim.lsp.buf_request_all(0, "workspace/symbol", params, function(responses)
		local results = {}
		for _, response in ipairs(responses) do
			if response.result then
				for _, result in ipairs(flatten_symbols(response.result)) do
					result.location.uri = utils.remove_matching_prefix(result.location.uri, "file://")
					if
						(
							result.kind == M.SYMBOL_KIND.CLASS
							or result.kind == M.SYMBOL_KIND.METHOD
							or result.kind == M.SYMBOL_KIND.FUNCTION
						)
						and utils.starts_with(result.location.uri, vim.fn.getcwd())
						and not is_not_source(result.location.uri)
					then
						table.insert(results, result)
					end
				end
			end
		end
		callback(vim.tbl_extend("force", results, files_symbols))
	end)
end

function M.get_document_symbols(query, callback)
	local params = {
		textDocument = vim.lsp.util.make_text_document_params(),
	}
	return vim.lsp.buf_request_all(0, "textDocument/documentSymbol", params, function(responses)
		local results = {}
		for _, response in ipairs(responses) do
			if response.result then
				for _, result in ipairs(flatten_symbols(response.result)) do
					if
						(
							result.kind == M.SYMBOL_KIND.CLASS
							or result.kind == M.SYMBOL_KIND.METHOD
							or result.kind == M.SYMBOL_KIND.FUNCTION
						) and utils.starts_with(result.name, query)
					then
						table.insert(results, result)
					end
				end
			end
		end
		callback(results)
	end)
end

return M

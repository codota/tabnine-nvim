local utils = require("tabnine.utils")
local M = {}

local SYMBOL_KIND = { FUNCTION = 12, CLASS = 5, METHOD = 6 }

local function flatten_symbols(symbols, result)
	result = result or {}

	for _, symbol in ipairs(symbols) do
		table.insert(result, symbol)

		if symbol.children then flatten_symbols(symbol.children, result) end
	end

	return result
end

function M.get_workspace_symbols(query, callback)
	local params = { query = query }

	return vim.lsp.buf_request_all(0, "workspace/symbol", params, function(responses)
		local results = {}
		for _, response in ipairs(responses) do
			if response.result then
				for _, result in ipairs(flatten_symbols(response.result)) do
					result.location.uri = utils.remove_matching_prefix(result.location.uri, "file://")
					if
						(
							result.kind == SYMBOL_KIND.CLASS
							or result.kind == SYMBOL_KIND.METHOD
							or result.kind == SYMBOL_KIND.FUNCTION
						)
						and utils.starts_with(result.location.uri, vim.fn.getcwd())
						and not is_not_source(result.location.uri)
					then
						table.insert(results, result)
					end
				end
			end
		end
		callback(results)
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
							result.kind == SYMBOL_KIND.CLASS
							or result.kind == SYMBOL_KIND.METHOD
							or result.kind == SYMBOL_KIND.FUNCTION
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

function is_not_source(symbol_path)
	local dirs = { "node_modules", "dist", "build", "target", "out" }
	for i, dir in ipairs(dirs) do
		if string.sub(symbol_path, 1, string.len(dir)) == dir then
			print("is not source")
			return true
		end
	end
	return false
end

return M

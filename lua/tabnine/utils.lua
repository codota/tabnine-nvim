local fn = vim.fn
local api = vim.api

local M = {}

function M.str_to_lines(str)
	return fn.split(str, "\n")
end

function M.lines_to_str(lines)
	return fn.join(lines, "\n")
end

function M.remove_matching_suffix(str, suffix)
	if not M.ends_with(str, suffix) then
		return str
	end
	return str:sub(1, -#suffix - 1)
end

function M.remove_matching_prefix(str, prefix)
	if not M.starts_with(str, prefix) then
		return str
	end
	return str:sub(#prefix)
end

function M.subset(tbl, from, to)
	return { unpack(tbl, from, to) }
end

function M.script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end

function M.prequire(...)
	local status, lib = pcall(require, ...)
	if status then
		return lib
	end
	return nil
end

function M.pumvisible()
	local cmp = M.prequire("cmp")
	if cmp then
		return cmp.visible()
	else
		return vim.fn.pumvisible() > 0
	end
end

function M.current_position()
	return { fn.line("."), fn.col(".") }
end

function M.ends_with(str, suffix)
	if str == "" then
		return true
	end

	return str:sub(-#suffix) == suffix
end

function M.starts_with(str, prefix)
	if str == "" then
		return true
	end

	return str:sub(1, #prefix) == prefix
end

function M.is_end_of_line()
	return fn.col(".") == fn.col("$")
end

function M.end_of_line()
	return api.nvim_buf_get_text(0, fn.line(".") - 1, fn.col(".") - 1, fn.line(".") - 1, fn.col("$"), {})[1]
end

return M

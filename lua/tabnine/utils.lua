local fn = vim.fn
local api = vim.api

local M = {}
local last_changedtick = vim.b.changedtick

function M.debounce(func, delay)
	local timer_id
	return function(...)
		if timer_id then fn.timer_stop(timer_id) end
		local args = { ... }
		timer_id = fn.timer_start(delay, function()
			func(unpack(args))
		end)
	end
end

function M.str_to_lines(str)
	return fn.split(str, "\n")
end

function M.lines_to_str(lines)
	return fn.join(lines, "\n")
end

function M.remove_matching_suffix(str, suffix)
	if not M.ends_with(str, suffix) then return str end
	return str:sub(1, -#suffix - 1)
end

function M.remove_matching_prefix(str, prefix)
	if not M.starts_with(str, prefix) then return str end
	return str:sub(#prefix + 1)
end

function M.subset(tbl, from, to)
	return { unpack(tbl, from, to) }
end

---returns the directory of the running script
---@return string
function M.script_dir()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)") or "./"
end

---returns the directory of the root of the module
---@return string
function M.module_dir()
	-- HACK: This only works if this file is not moved!
	return M.script_dir() .. "../.."
end

function M.prequire(...)
	local status, lib = pcall(require, ...)
	if status then return lib end
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
	if str == "" then return true end

	return str:sub(-#suffix) == suffix
end

function M.starts_with(str, prefix)
	if str == "" then return true end

	return str:sub(1, #prefix) == prefix
end

function M.is_end_of_line()
	return fn.col(".") == fn.col("$")
end

function M.end_of_line()
	return api.nvim_buf_get_text(0, fn.line(".") - 1, fn.col(".") - 1, fn.line(".") - 1, fn.col("$"), {})[1]
end

function M.document_changed()
	local current_changedtick = last_changedtick
	last_changedtick = vim.b.changedtick
	return last_changedtick > current_changedtick
end

function M.selected_text()
	local mode = vim.fn.mode()
	if mode ~= "v" and mode ~= "V" and mode ~= "" then return "" end
	local a_orig = vim.fn.getreg("a")
	vim.cmd([[silent! normal! "aygv]])
	local text = vim.fn.getreg("a")
	vim.fn.setreg("a", a_orig)
	return text
end

function M.set(array)
	local set = {}
	local uniqueValues = {}

	for _, value in ipairs(array) do
		if not set[value] then
			set[value] = true
			table.insert(uniqueValues, value)
		end
	end

	return uniqueValues
end

---Selects a given range of text
---@param range table
---@param selection_mode? 'charwise'|'linewise'|'blockwise'|'v'|'V'|'<C-v>'
function M.select_range(range, selection_mode)
	local start_row, start_col, end_row, end_col = range[1][1], range[1][2], range[2][1], range[2][2]

	local v_table = { charwise = "v", linewise = "V", blockwise = "<C-v>" }
	selection_mode = selection_mode or "charwise"

	-- Normalise selection_mode
	selection_mode = v_table[selection_mode] or selection_mode

	-- enter visual mode if normal or operator-pending (no) mode
	-- Why? According to https://learnvimscriptthehardway.stevelosh.com/chapters/15.html
	--   If your operator-pending mapping ends with some text visually selected, Vim will operate on that text.
	--   Otherwise, Vim will operate on the text between the original cursor position and the new position.
	local mode = api.nvim_get_mode()
	if mode.mode ~= selection_mode then
		-- Call to `nvim_replace_termcodes()` is needed for sending appropriate command to enter blockwise mode
		selection_mode = vim.api.nvim_replace_termcodes(selection_mode, true, true, true)
		api.nvim_cmd({ cmd = "normal", bang = true, args = { selection_mode } }, {})
	end

	api.nvim_win_set_cursor(0, { start_row, start_col - 1 })
	vim.cmd("normal! o")
	api.nvim_win_set_cursor(0, { end_row, end_col - 1 })
end

function M.read_file_into_buffer(file_path)
	local content = vim.fn.readfile(file_path)
	local bufnr = vim.api.nvim_create_buf(false, true)

	api.nvim_buf_set_lines(bufnr, 0, -1, false, content)

	return bufnr
end

return M

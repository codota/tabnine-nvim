local fn = vim.fn
local api = vim.api
local unpack = table.unpack or unpack
local pack = table.pack or vim.F.pack_len
local M = {}

---@param func fun(...: unknown): any the callback
---@param delay integer delay in milliseconds
---@return fun(...: unknown)
function M.debounce(func, delay)
	local timer_id
	return function(...)
		if timer_id then fn.timer_stop(timer_id) end
		local args = pack(...)
		timer_id = fn.timer_start(delay, function()
			return func(unpack(args, 1, args.n))
		end)
	end
end

---@param str string
---@return string[]
function M.str_to_lines(str)
	return fn.split(str, "\n")
end

---@param lines string[]
---@return string
function M.lines_to_str(lines)
	return fn.join(lines, "\n")
end

---@param str string
---@param suffix string
---@return string
function M.remove_matching_suffix(str, suffix)
	if not M.ends_with(str, suffix) then return str end
	return str:sub(1, -#suffix - 1)
end

---@param str string
---@param prefix string
---@return string
function M.remove_matching_prefix(str, prefix)
	if not M.starts_with(str, prefix) then return str end
	return str:sub(#prefix)
end

---@generic T
---@param tbl T[] | {n?: integer} The table to get a subset from
---@param from integer? defaults to 1
---@param to integer? defaults to tbl.n or #tbl.
---@return T[]
function M.subset(tbl, from, to)
	to = to or tbl.n or #tbl -- support table.pack values if no end given
	-- We can't use table.pack here because nvim_buf_set_extmark will error if non-integer keys are present
	-- Ideally, implementations would ignore string keys in an 'array'.
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

---pcall require. Returns nil if the module is not found.
---Note: use @module to manage types.
---@param modname string
---@return unknown?
function M.prequire(modname)
	local status, lib = pcall(require, modname)
	if status then return lib end
	return nil
end

---@return boolean
function M.pumvisible()
	local cmp = M.prequire("cmp")
	if cmp then return cmp.visible() end
	return vim.fn.pumvisible() > 0
end

---Return the position of the cursor
---@return number line, number column
function M.current_position()
	---@diagnostic disable-next-line: return-type-mismatch -- This is fine, they return non-nil values
	return fn.line("."), fn.col(".")
end

---Returns true if str ends with suffix.
---@param str string
---@param suffix string
---@return boolean
function M.ends_with(str, suffix)
	return str:sub(-#suffix) == suffix
end

---Returns true if str starts with prefix.
---@param str string
---@param prefix string
---@return boolean
function M.starts_with(str, prefix)
	return str:sub(1, #prefix) == prefix
end

---Returns true if the current cursor position is the end of the current line
---@return boolean
function M.is_end_of_line()
	return fn.col(".") == fn.col("$")
end

---Returns the text after the current cursor position to the end of the current line
---@return string
function M.end_of_line()
	return api.nvim_buf_get_text(0, fn.line(".") - 1, fn.col(".") - 1, fn.line(".") - 1, fn.col("$"), {})[1]
end

do
	---The last time we checked for a document change
	local last_changedtick = vim.b.changedtick
	---Returns true if the document has changed since the last call
	---@return boolean
	function M.document_changed()
		local current_changedtick = last_changedtick
		last_changedtick = vim.b.changedtick
		return last_changedtick > current_changedtick
	end
end

---Returns the currently selected text. If no in visual mode, returns the empty string.
---@return string
function M.selected_text()
	local mode = vim.fn.mode() ---@type string
	if mode ~= "v" and mode ~= "V" and mode ~= "" then return "" end
	local a_orig = vim.fn.getreg("a", 1)
	vim.cmd([[silent! normal! "aygv]])
	---@diagnostic disable-next-line: assign-type-mismatch -- This is fine. it returns a string
	local text = vim.fn.getreg("a") ---@type string
	vim.fn.setreg("a", a_orig)
	return text
end

---gets the unique values from the array
---@generic T
---@param array T[]
---@return T[]
function M.set(array)
	local set = {} ---@type table<unknown, true>
	local uniqueValues = {} ---@type unknown[]

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

return M

local api = vim.api
local M = {}
local original_window

local function create_floating_window(width_percentage, height_percentage, col_offset)
	local width = math.floor(vim.o.columns * width_percentage)
	local height = math.floor(vim.o.lines * height_percentage)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2) + col_offset

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}

	return api.nvim_open_win(0, true, opts)
end

M.insert = function(diff)
	original_window = api.nvim_get_current_win()
	if diff.comparableCode then
		local current_filetype = vim.bo.filetype

		-- Create two floating windows side by side
		local left_win = create_floating_window(0.4, 0.8, -math.floor(vim.o.columns * 0.2))
		local right_win = create_floating_window(0.4, 0.8, math.floor(vim.o.columns * 0.2))

		-- Create buffers for comparable and new code
		local comparable_buf = api.nvim_create_buf(false, true)
		local new_buf = api.nvim_create_buf(false, true)

		-- Set content and options for comparable code buffer
		api.nvim_buf_set_lines(comparable_buf, 0, -1, false, vim.split(diff.comparableCode, "\n"))
		api.nvim_buf_set_option(comparable_buf, "filetype", current_filetype)
		api.nvim_buf_set_option(comparable_buf, "modifiable", false)

		-- Set content and options for new code buffer
		api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(diff.newCode, "\n"))
		api.nvim_buf_set_option(new_buf, "filetype", current_filetype)
		api.nvim_buf_set_option(new_buf, "modifiable", false)

		-- Set buffers to respective windows
		api.nvim_win_set_buf(left_win, comparable_buf)
		api.nvim_win_set_buf(right_win, new_buf)

		-- Enable diff mode for both windows
		api.nvim_win_call(left_win, function()
			vim.cmd("diffthis")
		end)
		api.nvim_win_call(right_win, function()
			vim.cmd("diffthis")
		end)

		-- Store window IDs
		M.comparable_win = left_win
		M.new_win = right_win
	end
end

M.accept = function()
	if
		M.new_win
		and M.comparable_win
		and api.nvim_win_is_valid(M.new_win)
		and api.nvim_win_is_valid(M.comparable_win)
	then
		local new_code_buf = api.nvim_win_get_buf(M.new_win)
		local comparable_code_buf = api.nvim_win_get_buf(M.comparable_win)

		-- Get the content of the new code buffer
		local new_code = api.nvim_buf_get_lines(new_code_buf, 0, -1, false)

		-- Get the content of the comparable code buffer
		local comparable_code = api.nvim_buf_get_lines(comparable_code_buf, 0, -1, false)

		-- Switch to the original window
		api.nvim_set_current_win(original_window)
		local original_buf = api.nvim_get_current_buf()
		local original_lines = api.nvim_buf_get_lines(original_buf, 0, -1, false)

		-- Find the start and end positions of the comparable code in the original buffer
		local start_line, end_line
		for i, line in ipairs(original_lines) do
			if line == comparable_code[1] then
				start_line = i - 1
				end_line = start_line + #comparable_code - 1
				if vim.deep_equal(vim.list_slice(original_lines, start_line + 1, end_line + 1), comparable_code) then
					break
				end
			end
		end

		if start_line and end_line then
			-- Replace only the comparable code portion with the new code
			api.nvim_buf_set_lines(original_buf, start_line, end_line + 1, false, new_code)
		else
			print("Could not find the exact location of the comparable code in the original buffer.")
		end

		-- Close the diff windows
		M.close_diff_windows()
	else
		print("Tabnine diff windows not found or are no longer valid.")
	end
end

M.close_diff_windows = function()
	if M.comparable_win and api.nvim_win_is_valid(M.comparable_win) then api.nvim_win_close(M.comparable_win, true) end
	if M.new_win and api.nvim_win_is_valid(M.new_win) then api.nvim_win_close(M.new_win, true) end
	M.comparable_win = nil
	M.new_win = nil
	vim.cmd("augroup TabnineDiffFloating | autocmd! | augroup END")
end

M.reject = function()
	if
		M.new_win
		and M.comparable_win
		and api.nvim_win_is_valid(M.new_win)
		and api.nvim_win_is_valid(M.comparable_win)
	then
		-- Switch back to the original window
		api.nvim_set_current_win(original_window)

		-- Close the diff windows
		M.close_diff_windows()
	else
		print("Tabnine diff windows not found or are no longer valid.")
	end
end
return M

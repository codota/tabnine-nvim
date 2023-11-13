local uv = vim.uv or vim.loop
local cmd, args ---@type string, string[]
local unpack = table and table.unpack or unpack
local utils = require("tabnine.utils")
if uv.os_uname().sysname == "Windows_NT" then
	cmd = "pwsh.exe"
	args = { "-file", ".\\dl_binaries.ps1" }
else
	cmd = "./dl_binaries.sh"
	args = {}
end
local cmd_str = table.concat(vim.tbl_map(vim.fn.shellescape, { cmd, unpack(args) }), " ")

---Run the build script and call the callback when done.
---Note: this function will notify the user about progress and errors. Don't do it in the callback!
---callback will be called with false if the script fails to spawn.
---@param callback? fun(success: boolean):any?
---@return integer|nil pid
---@return string? error error message, if no pid
local function run_build(callback)
	print(("Starting tabnine-nvim build script: `%s`"):format(cmd_str))
	local stderr = assert(uv.new_pipe())

	local handle, pid = uv.spawn(
		cmd,
		{
			args = args,
			stdio = { nil, nil, stderr },
			cwd = utils.script_path(),
		},
		vim.schedule_wrap(function(code)
			local suc = code == 0
			if suc then
				print("tabnine-nvim build script finished successfully")
			else
				vim.api.nvim_err_writeln(("tabnine-nvim build script failed with exit code: %s"):format(code))
			end

			if callback then return callback(suc) end
		end)
	)

	if not handle then ---@cast pid string
		vim.api.nvim_err_writeln(("Could not spawn tabnine-nvim build script: `%s`. Error: %s"):format(cmd_str, pid))
		if callback then callback(false) end
		return nil, pid
	end ---@cast pid integer

	uv.read_start(
		stderr,
		vim.schedule_wrap(function(err, data)
			assert(not err, err)
			if not data then return end
			data = data:gsub("%s+$", ""):gsub("^%s+", "") -- remove trailing and leading whitespace
			if data == "" then return end
			return vim.api.nvim_err_writeln(("`%s`: ERROR: %s"):format(cmd_str, data))
		end)
	)
	return pid, nil
end
local function run_build_sync()
	print(("Starting tabnine-nvim build script: `%s`"):format(cmd_str))
	local f = assert(io.popen(cmd_str))
	f:close()
end

return {
	run_build = run_build,
	cmd_str = cmd_str,
	run_build_sync = run_build_sync,
}

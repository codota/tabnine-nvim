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
--- A human-readable description of the command -- for notifying and debugging purposes only
local cmd_str = table.concat({ cmd, unpack(args) }, " ")

---Run the build script and call the callback when done.
---Note: this function will notify the user about progress and errors. Don't do it in the callback!
---callback will be called with false if the script fails to spawn.
---@param callback? fun(success: boolean):any?
---@return integer|nil pid
---@return string? error error message, if no pid
local function run_build(callback)
	vim.notify(("Starting tabnine-nvim build script: '%s'"):format(cmd_str), vim.log.levels.INFO)
	local stderr = assert(uv.new_pipe())

	local handle, pid = uv.spawn(cmd, {
		args = args,
		stdio = { nil, nil, stderr },
		cwd = utils.script_path(),
	}, function(code)
		local suc = code == 0
		if suc then
			vim.notify("tabnine-nvim build script finished successfully", vim.log.levels.INFO)
		else
			vim.notify(("tabnine-nvim build script failed with exit code: %s"):format(code), vim.log.levels.WARN)
		end

		if callback then return callback(suc) end
	end)

	if not handle then ---@cast pid string
		vim.notify(("Could not spawn tabnine-nvim build script: '%s'. Error: %s"):format(cmd_str, pid), vim.log.levels.WARN)
		if callback then callback(false) end
		return nil, pid
	end ---@cast pid integer

	uv.read_start(stderr, function(err, data)
		assert(not err, err)
		if not data then return end
		data = data:gsub("%s+$", ""):gsub("^%s+", "") -- remove trailing and leading whitespace
		if data == "" then return end
		return vim.notify(("%s: ERROR: %s"):format(cmd_str, data), vim.log.levels.WARN)
	end)
	return pid, nil
end

return {
	run_build = run_build,
}

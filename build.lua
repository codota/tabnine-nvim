local uv = vim.uv or vim.loop
local cmd, args ---@type string, string[]
if uv.os_uname().sysname == "Windows_NT" then
	cmd = "pwsh.exe"
	args = { "-file", ".\\dl_binaries.ps1" }
else
	cmd = "./dl_binaries.sh"
	args = {}
end

local stderr = assert(uv.new_pipe())

local handle, pid = uv.spawn(cmd, {
	args = args,
	stdio = { nil, nil, stderr },
}, function(code)
	if code == 0 then
		return vim.notify("tabnine-nvim build script finished successfully", vim.log.levels.INFO)
	else
		return vim.notify(("tabnine-nvim build script failed with exit code: %s"):format(code), vim.log.levels.WARN)
	end
end)

if not handle then
	local err = pid ---@cast err string
	vim.notify(("Could not spawn tabnine-nvim build script: '%s'. Error: %s"):format(cmd, err), vim.log.levels.WARN)
	return
end

uv.read_start(stderr, function(err, data)
	assert(not err, err)
	if not data then return end
	data = data:gsub("%s+$", ""):gsub("^%s+", "") -- remove trailing and leading whitespace
	if data == "" then return end
	return vim.notify(("%s: ERROR: %s"):format(cmd, data), vim.log.levels.WARN)
end)

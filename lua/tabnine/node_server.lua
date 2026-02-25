local uv = vim.uv or vim.loop
local fn = vim.fn
local utils = require("tabnine.utils")
local config = require("tabnine.config")
local ports = require("tabnine.ports")

local NodeServer = {}

local NODE_VERSION = "v24.12.0"
local NODE_SERVER_ENTRY_POINT = "index.js"
local RESTART_THRESHOLD = 5

local function get_platform_identifier()
	local os_uname = uv.os_uname()
	local sysname = os_uname.sysname
	local machine = os_uname.machine

	local platform_name
	if sysname == "Darwin" then
		platform_name = "macos"
	elseif sysname == "Linux" then
		platform_name = "linux"
	elseif sysname == "Windows_NT" then
		platform_name = "windows"
	else
		return nil
	end

	local arch_name
	if machine == "x86_64" or machine == "amd64" then
		arch_name = "x64"
	elseif machine == "aarch64" or machine == "arm64" then
		arch_name = "arm64"
	else
		return nil
	end

	return platform_name .. "-" .. arch_name
end

local function installer_binary_name()
	local os_uname = uv.os_uname()
	if os_uname.sysname == "Windows_NT" then
		return "tabnine-node-installer.exe"
	else
		return "tabnine-node-installer"
	end
end

local function node_binary_name()
	local os_uname = uv.os_uname()
	if os_uname.sysname == "Windows_NT" then
		return "node.exe"
	else
		return "bin/node"
	end
end

local function installer_path()
	local platform_id = get_platform_identifier()
	if not platform_id then
		return nil
	end
	return utils.module_dir() .. "/node/installer/" .. platform_id .. "/" .. installer_binary_name()
end

local function server_path()
	local external_path = vim.env.TABNINE_NODE_SERVER_PATH
	if external_path then
		return external_path
	end
	return utils.module_dir() .. "/node/server/" .. NODE_SERVER_ENTRY_POINT
end

local function cloud_host()
	if config.is_enterprise() then
		return config.get_config().tabnine_enterprise_host or "https://update.tabnine.com"
	end
	return "https://update.tabnine.com"
end

local function ensure_node_runtime(callback)
	local path = installer_path()
	if not path or fn.executable(path) ~= 1 then
		callback(nil, "Node installer not found")
		return
	end

	local stdout_data = ""
	local stderr_data = ""
	local stdout = uv.new_pipe()
	local stderr = uv.new_pipe()

	local handle
	handle = uv.spawn(path, {
		args = { cloud_host(), NODE_VERSION },
		stdio = { nil, stdout, stderr },
	}, function(code, _)
		stdout:close()
		stderr:close()
		handle:close()

		if code ~= 0 then
			callback(nil, "Node installer failed: " .. stderr_data)
			return
		end

		local runtime_dir = stdout_data:gsub("%s+$", "")
		if runtime_dir == "" then
			callback(nil, "Node installer returned empty path")
			return
		end

		callback(runtime_dir .. "/" .. node_binary_name(), nil)
	end)

	stdout:read_start(function(_, data)
		if data then
			stdout_data = stdout_data .. data
		end
	end)

	stderr:read_start(function(_, data)
		if data then
			stderr_data = stderr_data .. data
		end
	end)
end

function NodeServer:start(node_path)
	if self.handle then
		return
	end

	local srv_path = server_path()
	if fn.filereadable(srv_path) ~= 1 then
		vim.notify("Node-server not found at " .. srv_path, vim.log.levels.ERROR)
		return
	end

	local node_server_port = ports.get_node_server_port()
	if not node_server_port then
		vim.notify("Node server port not initialized", vim.log.levels.ERROR)
		return
	end

	local args = {
		srv_path,
		"--port",
		tostring(node_server_port),
		"--tabnine-host",
		cloud_host(),
	}

	local rust_server_port = ports.get_rust_server_port()
	if rust_server_port then
		table.insert(args, "--rust-port")
		table.insert(args, tostring(rust_server_port))
	end

	self.stdout = uv.new_pipe()
	self.stderr = uv.new_pipe()
	self.handle, self.pid = uv.spawn(node_path, {
		args = args,
		stdio = { nil, self.stdout, self.stderr },
	}, function(_, _)
		self.handle, self.pid = nil, nil
		if self.stdout then
			uv.read_stop(self.stdout)
		end
		if self.stderr then
			uv.read_stop(self.stderr)
		end
		self.stdout, self.stderr = nil, nil

		vim.schedule(function()
			self:restart()
		end)
	end)
end

function NodeServer:stop()
	if self.handle then
		uv.process_kill(self.handle, "sigterm")
		self.handle, self.pid = nil, nil
	end
	if self.stdout then
		uv.read_stop(self.stdout)
		self.stdout = nil
	end
	if self.stderr then
		uv.read_stop(self.stderr)
		self.stderr = nil
	end
	self.restart_counter = 0
end

function NodeServer:restart()
	self.restart_counter = self.restart_counter + 1

	if self.restart_counter >= RESTART_THRESHOLD then
		vim.notify("Node-server exceeded restart threshold. Giving up.", vim.log.levels.WARN)
		return
	end

	local backoff = math.min(1000 * (2 ^ self.restart_counter), 30000)
	vim.defer_fn(function()
		self:ensure_running()
	end, backoff)
end

function NodeServer:is_running()
	return self.handle ~= nil
end

function NodeServer:get_port()
	return ports.get_node_server_port()
end

function NodeServer:ensure_running(callback)
	callback = callback or function() end

	if self:is_running() then
		callback()
		return
	end

	ensure_node_runtime(function(node_path, err)
		if err then
			vim.schedule(function()
				vim.notify("Failed to ensure Node runtime: " .. err, vim.log.levels.ERROR)
			end)
			callback()
			return
		end

		vim.schedule(function()
			self:start(node_path)
			callback()
		end)
	end)
end

function NodeServer:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.stdout = nil
	self.stderr = nil
	self.handle = nil
	self.pid = nil
	self.restart_counter = 0

	return o
end

return NodeServer:new()

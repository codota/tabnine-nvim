local uv = vim.loop
local fn = vim.fn
local json = vim.json
local consts = require("tabnine.consts")
local semver = require("tabnine.third_party.semver.semver")
local utils = require("tabnine.utils")
local TabnineBinary = {}
local config = require("tabnine.config")

local api_version = "4.4.223"
local binaries_path = utils.script_path() .. "/binaries"

local function arch_and_platform()
	local os_uname = uv.os_uname()

	if os_uname.sysname == "Linux" and os_uname.machine == "x86_64" then
		return "x86_64-unknown-linux-musl"
	elseif os_uname.sysname == "Darwin" and os_uname.machine == "arm64" then
		return "aarch64-apple-darwin"
	elseif os_uname.sysname == "Darwin" then
		return "x86_64-apple-darwin"
	elseif os_uname.sysname == "Windows_NT" and os_uname.machine == "x86_64" then
		return "x86_64-pc-windows-gnu"
	elseif os_uname.sysname == "Windows_NT" then
		return "i686-pc-windows-gnu"
	else
		return nil
	end
end

local function binary_name()
	local os_uname = uv.os_uname()
	if os_uname.sysname == "Windows_NT" then
		return "TabNine.exe"
	else
		return "TabNine"
	end
end

local function binary_path()
	local paths = vim.tbl_map(function(path)
		return fn.fnamemodify(path, ":t")
	end, fn.glob(binaries_path .. "/*", true, true))

	paths = vim.tbl_map(function(path)
		return semver(path)
	end, paths)

	table.sort(paths)

	local version = paths[#paths]
	if not version then
		return nil -- Is it installed?
	end
	local machine = arch_and_platform()
	if not machine then
		return nil -- Is this machine supported?
	end
	local binary = binaries_path .. "/" .. tostring(version) .. "/" .. machine .. "/" .. binary_name()

	if vim.fn.filereadable(binary) then -- Double check that it's installed
		return binary
	else
		return nil -- File doesn't exist or isn't readable. Is it installed?
	end
end

local function optional_args()
	local config = config.get_config()
	local args = {}
	if config.log_file_path then table.insert(args, "--log-file-path=" .. config.log_file_path) end
	if config.tabnine_enterprise_host then table.insert(args, "--cloud2_url=" .. config.tabnine_enterprise_host) end
	return args
end

function TabnineBinary:start()
	self.stdin = uv.new_pipe()
	self.stdout = uv.new_pipe()
	self.stderr = uv.new_pipe()
	self.handle, self.pid = uv.spawn(self.binary_path, {
		args = vim.list_extend({
			"--client",
			"nvim",
			"--client-metadata",
			"ide-restart-counter=" .. self.restart_counter,
			"pluginVersion=" .. consts.plugin_version,
		}, optional_args()),
		stdio = { self.stdin, self.stdout, self.stderr },
	}, function()
		self.handle, self.pid = nil, nil
		uv.read_stop(self.stdout)
		uv.read_stop(self.stderr)
		self.stdout, self.stderr, self.stdin = nil, nil, nil
	end)

	uv.read_start(
		self.stdout,
		vim.schedule_wrap(function(error, chunk)
			if chunk then
				for _, line in pairs(utils.str_to_lines(chunk)) do
					local callback = table.remove(self.callbacks)
					if not callback.cancelled then
						local decoded = vim.json.decode(line, { luanil = { object = true, array = true } })
						callback.callback(decoded)
					end
				end
			elseif error then
				print("tabnine binary read_start error", error)
			end
		end)
	)
end

function TabnineBinary:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.stdin = nil
	self.stdout = nil
	self.stderr = nil
	self.restart_counter = 0
	self.handle = nil
	self.pid = nil
	self.binary_path = binary_path()
	self.callbacks = {}

	return o
end

function TabnineBinary:request(request, on_response)
	if not self.binary_path then
		return function() end -- To avoid breaking user configurations
	end
	if not self.pid then
		self.restart_counter = self.restart_counter + 1
		self:start()
	end
	uv.write(self.stdin, json.encode({ request = request, version = api_version }) .. "\n")
	local callback = { cancelled = false, callback = on_response }
	local function cancel()
		callback.cancelled = true
	end

	table.insert(self.callbacks, 1, callback)
	return cancel
end

return TabnineBinary:new()

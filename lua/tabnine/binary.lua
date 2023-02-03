local uv = vim.loop
local fn = vim.fn
local json = vim.json
local utils = require("tabnine.utils")
local consts = require("tabnine.consts")
local semver = require("tabnine.third_party.semver.semver")
local TabnineBinary = {}

json.encode_empty_table_as_object(true)

local api_version = "4.4.71"
local binaries_path = utils.script_path() .. "../../binaries"

local function arch_and_platform()
	local os_uname = uv.os_uname()

	if os_uname.sysname == "Linux" and os_uname.machine == "x86_64" then
		return "x86_64-unknown-linux-musl"
	elseif os_uname.sysname == "Darwin" and os_uname.machine == "arm64" then
		return "aarch64-apple-darwin"
	elseif os_uname.sysname == "Darwin" then
		return "x86_64-apple-darwin"
	elseif fn.has("win32") then
		return "windows-gnu"
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

	return binaries_path .. "/" .. tostring(paths[#paths]) .. "/" .. arch_and_platform() .. "/TabNine"
end

function TabnineBinary:start()
	self.handle, self.pid = uv.spawn(binary_path(), {
		args = {
			"--client",
			"nvim",
			"--client-metadata",
			"ide-restart-counter=" .. self.restart_counter,
			"pluginVersion=" .. consts.plugin_version,
		},
		stdio = { self.stdin, self.stdout, self.stderr },
	}, function()
		self.handle, self.pid = nil, nil
		uv.read_stop(self.stdout)
	end)

	uv.read_start(
		self.stdout,
		vim.schedule_wrap(function(error, chunk)
			if chunk then
				for _, line in pairs(utils.str_to_lines(chunk)) do
					local callback = table.remove(self.callbacks)
					if not callback.cancelled then
						callback.callback(vim.json.decode(line))
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
	self.stdin = uv.new_pipe()
	self.stdout = uv.new_pipe()
	self.stderr = uv.new_pipe()
	self.restart_counter = 0
	self.handle = nil
	self.pid = nil
	self.callbacks = {}

	return o
end

function TabnineBinary:request(request, on_response)
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

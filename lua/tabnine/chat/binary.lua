local uv = vim.loop
local json = vim.json
local utils = require("tabnine.utils")
local ChatBinary = {}
local on_closed_callbacks = {}

local function binary_name()
	local os_uname = uv.os_uname()
	if os_uname.sysname == "Windows_NT" then
		return "tabnine_chat.exe"
	else
		return "tabnine_chat"
	end
end

local binary_path = utils.module_dir() .. "/chat/target/release/" .. binary_name()

function ChatBinary:available()
	return vim.fn.executable(binary_path) == 1
end

function ChatBinary:close()
	if self.handle and not self.handle:is_closing() then
		self.handle:close()
		uv.kill(self.pid, "sigterm")
		self.handle = nil
		self.pid = nil
		self.stdin = nil
		uv.read_stop(self.stdout)
		uv.read_stop(self.stderr)
		self.stdout = nil
		self.stderr = nil
	end
end

function ChatBinary:is_open()
	if self.handle == nil then return false end
	return self.handle:is_active()
end

function ChatBinary:on_closed(callback)
	on_closed_callbacks[#on_closed_callbacks + 1] = callback
end

local function on_closed()
	for _, callback in ipairs(on_closed_callbacks) do
		callback()
	end
	on_closed_callbacks = {}
end

function ChatBinary:start()
	if self.pid then return end

	self.stdin = uv.new_pipe()
	self.stdout = uv.new_pipe()
	self.stderr = uv.new_pipe()

	self.handle, self.pid = uv.spawn(
		binary_path,
		{
			stdio = { self.stdin, self.stdout, self.stderr },
		},
		vim.schedule_wrap(function(code, signal) -- on exit
			if signal ~= 0 or code ~= 0 then
				local err = "Something went wrong running Tabnine chat"
				if signal ~= 0 then
					err = err .. (" (signal %d)"):format(signal)
				else
					err = err .. (" (exit code %d)"):format(code)
				end
				vim.notify(err, vim.log.levels.WARN)
			end
			on_closed()
			self:close()
		end)
	)

	utils.read_lines_start(
		self.stdout,
		vim.schedule_wrap(function(line)
			local message = vim.json.decode(line, { luanil = { object = true, array = true } })
			local handler = self.registry[message.command]
			if handler then
				handler(message.data, function(payload)
					self:post_message({
						id = message.id,
						payload = payload,
					})
				end)
			else
				self:post_message({ id = message.id, error = "not_implemented" })
			end
		end),
		vim.schedule_wrap(function(error)
			print("error reading chat binary", error)
		end)
	)
end

function ChatBinary:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.stdin = nil
	self.stdout = nil
	self.stderr = nil
	self.handle = nil
	self.pid = nil
	self.registry = {}

	return o
end

function ChatBinary:register_event(event, handler)
	self.registry[event] = handler
end

function ChatBinary:post_message(message)
	if self.stdin then
		uv.write(self.stdin, json.encode(message) .. "\n")
	else
		vim.notify("tabnine chat not found, did you remember to start it first?", vim.log.levels.WARN)
	end
end

return ChatBinary:new()

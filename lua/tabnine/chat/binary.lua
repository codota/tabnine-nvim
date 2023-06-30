local uv = vim.loop
local json = vim.json
local utils = require("tabnine.utils")
local ChatBinary = {}

local function binary_name()
	local os_uname = uv.os_uname()
	if os_uname.sysname == "Windows_NT" then
		return "tabnine_chat.exe"
	else
		return "tabnine_chat"
	end
end

local binary_path = utils.script_path() .. "/../chat/target/release/" .. binary_name()

function ChatBinary:available()
  return vim.fn.executable(binary_path) == 1
end

function ChatBinary:start()
	if self.pid then
		return
	end

	self.stdin = uv.new_pipe()
	self.stdout = uv.new_pipe()
	self.stderr = uv.new_pipe()

	self.handle, self.pid = uv.spawn(binary_path, {
		stdio = { self.stdin, self.stdout, self.stderr },
	}, function()
		self.handle, self.pid, self.registry = nil, nil, {}
		uv.read_stop(self.stdout)
	end)

	uv.read_start(
		self.stdout,
		vim.schedule_wrap(function(error, chunk)
			if chunk then
				for _, line in pairs(utils.str_to_lines(chunk)) do
					local message = vim.json.decode(line)
					local handler = self.registry[message.command]
					if handler then
						handler(message.data, function(payload)
							if payload then
								self:post_message(message.id, payload)
							end
						end)
					end
				end
			elseif error then
				print("chat binary read_start error", error)
			end
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

function ChatBinary:post_message(id, payload)
	uv.write(self.stdin, json.encode({ id = id, payload = payload }) .. "\n")
end

return ChatBinary:new()

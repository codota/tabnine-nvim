local uv = vim.loop

local M = require("lualine.component"):extend()
local tabnine_binary = require("tabnine.binary")
local status_prefix = "⌬ tabnine"
local service_level = nil

local function poll_service_level()
	local timer = uv.new_timer()
	timer:start(
		0,
		5000,
		vim.schedule_wrap(function()
			tabnine_binary:request({ State = {} }, function(response)
				if response.service_level == "Pro" or response.service_level == "Trial" then
					service_level = "pro"
				elseif response.service_level == "Business" then
					service_level = "enterprise"
				else
					service_level = "starter"
				end
			end)
		end)
	)
end

function M.init(self, options)
	M.super.init(self, options)
	poll_service_level()
end

function M.update_status()
	if not service_level then
		return status_prefix .. " loading"
	end
	return status_prefix .. " " .. service_level
end

return M

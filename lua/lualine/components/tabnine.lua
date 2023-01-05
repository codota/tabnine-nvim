local M = require("lualine.component"):extend()
local tabnine = require("tabnine")
local status_prefix = "⌬ tabnine"

function M.init(self, options)
	M.super.init(self, options)
end

function M.update_status()
	local service_level = tabnine.service_level()

	if not service_level then
		return status_prefix .. " disabled"
	end

	if service_level == "Pro" or service_level == "Trial" then
		service_level = "pro"
	elseif service_level == "Business" then
		service_level = "enterprise"
	else
		service_level = "starter"
	end

	return status_prefix .. " " .. service_level
end

return M

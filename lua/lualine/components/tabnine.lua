-- if lualine does not exists
local M = require('lualine.component'):extend()
local status_prefix = "⌬ tabnine"
local status = status_prefix .. ": disabled";

function M.update_service_level(service_level)
    if service_level == "Pro" or service_level == "Trial" then
        service_level = "pro"
    elseif service_level == "Business" then
        service_level = "business"
    else
        service_level = "free"
    end

    status = status_prefix .. " " .. service_level
end

function M.init(self, options) M.super.init(self, options) end

function M.update_status() return status end

return M

local M = require('lualine.component'):extend()
local tabnine = require('tabnine')
local status_prefix = "⌬ tabnine"
local short = "⌬"

function M.init(self, options) M.super.init(self, options) end

function M.update_status()
    local service_level = tabnine.service_level()

    if not service_level then return status_prefix .. " disabled" end

    if service_level == "Pro" or service_level == "Trial" then
        service_level = "pro"
        -- if config.use_short_prefix then
        -- Apply purple color to the `short` icon
    elseif service_level == "Business" then
        service_level = "business"
        -- if config.use_short_prefix then
        -- Apply magenta color to the `short` icon
    else
        service_level = "starter"
    end

    if true then -- if config.use_short_prefix then
      return short;
    else
      return status_prefix .. " " .. service_level
    end
end

return M

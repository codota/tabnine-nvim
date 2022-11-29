local fn = vim.fn
local uv = vim.loop

-- if lualine does not exists
local M = require('lualine.component'):extend()
local tabnine_binary = require('tabnine.binary')
local service_level = "free"

local function update_service_level(state)
    if state.service_level == "Pro" or state.service_level == "Trial" then
        service_level = "pro"
    elseif state.service_level == "Business" then
        service_level = "business"
    else
        service_level = "free"
    end
end

function M.init(self, options)
    M.super.init(self, options)
    local timer = uv.new_timer()
    tabnine_binary.on_response(function(state)
        if state.service_level then update_service_level(state) end
    end)
    timer:start(0, 5000, function()
        vim.schedule(function() tabnine_binary.request({State = {}}) end)
    end)
end

function M.update_status() return "⌬ tabnine " .. service_level end

return M

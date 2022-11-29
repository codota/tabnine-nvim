local fn = vim.fn
local uv = vim.loop

-- if lualine does not exists
local M = require('lualine.component'):extend()
local tabnine_binary = require('tabnine.binary')
local service_level = "free"

function M.init(self, options)
    M.super.init(self, options)
    local timer = uv.new_timer()
    timer:start(10000, 0, function()
        vim.schedule(function()
            tabnine_binary.request({State = {filename = "_"}}, function(state)
                vim.schedule(function()
                    print(fn.json_encode(state))
                end)
                if state.service_level == "Pro" or state.service_level ==
                    "Trial" then
                    service_level = "pro"
                elseif state.service_level == "Business" then
                    service_level = "business"
                else
                    service_level = "free"
                end
            end)
        end)
    end)
end

function M.update_status() return "⌬ tabnine " .. service_level end

return M

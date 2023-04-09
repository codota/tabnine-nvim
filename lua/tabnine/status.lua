local uv = vim.loop
local fn = vim.fn
local utils = require("tabnine.utils")

local M = {}
local DISABLED_FILE = utils.script_path() .. "/.disabled"
local tabnine_binary = require("tabnine.binary")
local state = require("tabnine.state")
local service_level = nil
local status_prefix = "⌬ tabnine"

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

function M.setup()
	poll_service_level()
	local _, disabled_file_exists = pcall(fn.filereadable, DISABLED_FILE)
	active = disabled_file_exists == 0
end

function M.enable_tabnine()
	pcall(fn.delete, DISABLED_FILE)
	state.active = true
end

function M.disable_tabnine()
	pcall(fn.writefile, { "" }, DISABLED_FILE, "b")
	state.active = false
end

function M.toggle_tabnine()
	if state.active then
		M.disable_tabnine()
	else
		M.enable_tabnine()
	end
end

function M.status()
	if state.active == false then
		return status_prefix .. " disabled"
	end

	if not service_level then
		return status_prefix .. " loading"
	end

	return status_prefix .. " " .. service_level
end

return M

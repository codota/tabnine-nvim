local tabnine_binary = require("tabnine.binary")
local fn = vim.fn
local uv = vim.loop

local M = {}

function M.setup()
	local timer = uv.new_timer()
	timer:start(
		0,
		30000,
		vim.schedule_wrap(function()
			tabnine_binary:request({ Workspace = { root_paths = { fn.getcwd() } } }, function() end)
		end)
	)
end

return M

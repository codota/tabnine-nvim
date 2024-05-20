local tabnine_binary = require("tabnine.binary")
local uv = vim.loop
local lsp = vim.lsp
local utils = require("tabnine.utils")

local M = {}

function M.setup()
	local timer = uv.new_timer()

	timer:start(
		0,
		30000,
		vim.schedule_wrap(function()
			local client_count = 0

			if vim.fn.has('nvim-0.11') == 1 then
				client_count = #vim.lsp.get_clients()
			else
				client_count = #vim.lsp.buf_get_clients()
			end
				
			if client_count > 0 then
				local root_paths = utils.set(lsp.buf.list_workspace_folders())
				tabnine_binary:request({ Workspace = { root_paths = root_paths } }, function() end)
			end
		end)
	)
end

return M

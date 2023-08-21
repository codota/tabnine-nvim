local M = require("lualine.component"):extend()
local status = require("tabnine.status")

function M.init(self, options)
	M.super.init(self, options)
end

function M.update_status()
	return status.status()
end

return M

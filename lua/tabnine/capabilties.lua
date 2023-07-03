local M
local capabilities = {}
local tabnine_binary = require("tabnine.binary")

function M.refresh_capabilities()
	tabnine_binary:request({ Features = { dummy = true } }, function(response)
		capabilities = response
	end)
end

function M.is_capability_enabled(capability)
	for _, capability in ipairs(capabilities) do
		if capability.name == capability then
			return true
		end
	end
	return false
end

return M

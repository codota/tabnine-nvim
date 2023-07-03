local user_commands = require("tabnine.chat.user_commands")
local auto_commands = require("tabnine.chat.auto_commands")

local M = {}
function M.setup()
	user_commands.setup()
	auto_commands.setup()
end

return M

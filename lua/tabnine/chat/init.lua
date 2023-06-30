local chat_binary = require("tabnine.chat.binary")
local fn = vim.fn
local utils = require("tabnine.utils")
local tabnine_binary = require("tabnine.binary")
local api = vim.api

local M = {}

local CHAT_STATE_FILE = utils.script_path() .. "/chat_state.json"
local chat_state = nil

local function read_chat_state()
	if fn.filereadable(CHAT_STATE_FILE) == 1 then
		local lines = fn.readfile(CHAT_STATE_FILE)
		if #lines > 0 then
			return vim.json.decode(lines[1])
		end
		return { conversations = {} }
	end
	return { conversations = {} }
end

local function write_chat_state(state)
	fn.writefile({ vim.json.encode(state) }, CHAT_STATE_FILE)
end

local function register_events()
	chat_binary:register_event("init", function(_, answer)
		answer({ ide = "ij", isDarkTheme = true })
	end)

	chat_binary:register_event("update_chat_conversation", function(conversation)
		chat_state.conversations[conversation.id] = {
			id = conversation.id,
			messages = conversation.messages,
		}
		write_chat_state(chat_state)
	end)

	chat_binary:register_event("get_chat_state", function(_, answer)
		answer(chat_state) -- this may not work good with multiple chats
	end)
	chat_binary:register_event("get_user", function(_, answer)
		tabnine_binary:request({ State = { dummy = true } }, function(state)
			answer({ token = state.access_token, username = state.user_name })
		end)
	end)
	chat_binary:register_event("insert-at-cursor", function(message, _)
		local lines = utils.str_to_lines(message.code)
		api.nvim_buf_set_text(0, fn.line(".") - 1, fn.col(".") - 1, fn.line(".") - 1, fn.col(".") - 1, lines)
	end)
	chat_binary:register_event("get_editor_context", function(_, answer)
		local file_code_table = api.nvim_buf_get_text(0, 0, 0, fn.line("$") - 1, fn.col("$,$") - 1, {})
		local file_code = table.concat(file_code_table, "\n")
		answer({
			fileCode = file_code,
			selectedCode = "",
			selectedCodeUsages = {},
		})
	end)
end

function M.setup()
	if not chat_binary:available() then
		vim.notify(
			"tabnine_chat binary not found, did you remember to build it first? `cargo build --release` inside `chat/` directory"
		)
		return
	end
	chat_state = read_chat_state()
	register_events()
	chat_binary:start()
end

return M

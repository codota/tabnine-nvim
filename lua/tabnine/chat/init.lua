local chat_binary = require("tabnine.chat.binary")
local fn = vim.fn
local tabnine_binary = require("tabnine.binary")
local utils = require("tabnine.utils")
local api = vim.api
local config = require("tabnine.config")

local M = { enabled = false }

local CHAT_STATE_FILE = utils.script_path() .. "/../chat_state.json"
local CHAT_SETTINGS_FILE = utils.script_path() .. "/../chat_settings.json"

local chat_state = nil
local chat_settings = nil
local initialized = false

local function get_diagnostics()
	return vim.tbl_map(function(diagnostic)
		return {
			errorMessage = diagnostic.message,
			lineCode = api.nvim_buf_get_lines(0, diagnostic.lnum, diagnostic.lnum + 1, true)[1],
			lineNumber = diagnostic.lnum + 1,
		}
	end, vim.diagnostic.get(0))
end

local function read_chat_state()
	if fn.filereadable(CHAT_STATE_FILE) == 1 then
		local lines = fn.readfile(CHAT_STATE_FILE)
		if #lines > 0 then return vim.json.decode(lines[1], { luanil = { object = true, array = true } }) end
		return { conversations = {} }
	end
	return { conversations = {} }
end

local function read_chat_settings()
	if fn.filereadable(CHAT_SETTINGS_FILE) == 1 then
		local lines = fn.readfile(CHAT_SETTINGS_FILE)
		if #lines > 0 then return vim.json.decode(lines[1], { luanil = { object = true, array = true } }) end
		return {}
	end
	return {}
end

local function write_chat_state(state)
	fn.writefile({ vim.json.encode(state) }, CHAT_STATE_FILE)
end

local function write_chat_settings(settings)
	fn.writefile({ vim.json.encode(settings) }, CHAT_SETTINGS_FILE)
end

local function register_events(on_init)
	chat_binary:register_event("get_capabilities", function(_, answer)
		tabnine_binary:request({
			Features = { dummy = true },
		}, function(response)
			answer({
				enabledFeatures = response.enabled_features,
			})
		end)
	end)

	chat_binary:register_event("workspace_folders", function(_, answer)
		answer({
			rootPaths = { fn.getcwd() },
		})
	end)

	chat_binary:register_event("get_server_url", function(request, answer)
		tabnine_binary:request({
			ChatCommunicatorAddress = { kind = request.kind },
		}, function(response)
			answer({
				serverUrl = response.address,
			})
		end)
	end)

	chat_binary:register_event("init", function(_, answer)
		local init = { ide = "ij", isDarkTheme = true }
		if config.is_enterprise() then init.serverUrl = config.get_config().tabnine_enterprise_host end
		answer(init)
		if not initialized and on_init then
			on_init()
			initialized = true
		end
	end)

	chat_binary:register_event("clear_all_chat_conversations", function(_, answer)
		chat_state.conversations = {}
		write_chat_state(chat_state)
		answer(chat_state)
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

	chat_binary:register_event("get_settings", function(_, answer)
		answer(chat_settings)
	end)

	chat_binary:register_event("update_settings", function(settings)
		chat_settings = settings
		write_chat_settings(settings)
	end)

	chat_binary:register_event("get_user", function(_, answer)
		tabnine_binary:request({ State = { dummy = true } }, function(state)
			answer({
				token = state.access_token,
				username = state.user_name,
				avatarUrl = state.user_avatar_url,
				serviceLevel = state.service_level,
			})
		end)
	end)
	chat_binary:register_event("insert_at_cursor", function(message, _)
		local lines = utils.str_to_lines(message.code)
		api.nvim_buf_set_text(0, fn.line("v") - 1, fn.col("v") - 1, fn.line(".") - 1, fn.col(".") - 1, lines)
	end)

	chat_binary:register_event("get_basic_context", function(_, answer)
		tabnine_binary:request({
			FileMetadata = { path = api.nvim_buf_get_option(0, "filetype") },
		}, function(metadata)
			answer({
				fileUri = api.nvim_buf_get_name(0),
				language = api.nvim_buf_get_option(0, "filetype"),
				metadata = metadata,
			})
		end)
	end)

	chat_binary:register_event("get_enriching_context", function(request, answer)
		local contextTypesSet = utils.set(request.contextTypes)
		local enrichingContextData = vim.tbl_map(function(contextType)
			if contextType == "Editor" then
				local file_code_table = api.nvim_buf_get_text(0, 0, 0, fn.line("$") - 1, fn.col("$,$") - 1, {})
				local file_code = table.concat(file_code_table, "\n")

				return {
					type = "Editor",
					fileCode = file_code,
					currentLineIndex = api.nvim_win_get_cursor(0)[1],
					selectedCodeUsages = {},
				}
			elseif contextType == "Diagnostics" then
				return {
					type = "Diagnostics",
					diagnostics = get_diagnostics(),
				}
			elseif contextType == "Workspace" then
				return {} -- not implemented
			elseif contextType == "NFC" then
				return {} -- not implemented
			else
				return {}
			end
		end, contextTypesSet)

		answer({ enrichingContextData = enrichingContextData })
	end)

	chat_binary:register_event("get_selected_code", function(_, answer)
		local selected_code = utils.selected_text()

		answer({
			code = selected_code,
			startLine = vim.fn.getpos("'<")[2],
			endLine = vim.fn.getpos("'>")[2],
		})
	end)

	chat_binary:register_event("send_event", function(event)
		tabnine_binary:request({
			Event = { name = event.eventName, properties = event.properties },
		}, function() end)
	end)
end

function M.clear_conversation()
	chat_binary:post_message({ command = "clear-conversation" })
end

function M.new_conversation()
	M.focus()
	chat_binary:post_message({ command = "create-new-conversation" })
	chat_binary:post_message({ command = "focus-input" })
end

function M.set_always_on_top(value)
	chat_binary:post_message({ command = "set_always_on_top", data = value })
end

function M.submit_message(message)
	chat_binary:post_message({ command = "submit-message", data = { input = message } })
end

function M.is_open()
	return chat_binary:is_open()
end

function M.close()
	chat_binary:close()
end

function M.open(on_ready)
	if not M.enabled then
		vim.notify("Tabnine Chat is available only for Pro users")
		return
	end

	if not chat_binary:available() then
		vim.notify(
			"tabnine_chat binary not found, did you remember to build it first? `cargo build --release` inside `chat/` directory"
		)
		return
	end

	if M.is_open() then
		M.focus()
		if on_ready then on_ready() end
		return
	end

	chat_state = read_chat_state()
	chat_settings = read_chat_settings()
	register_events(on_ready)
	chat_binary:start()
end

function M.focus()
	chat_binary:post_message({ command = "focus" })
end

function M.setup()
	M.enabled = true
end

return M

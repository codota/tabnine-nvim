local chat_binary = require("tabnine.chat.binary")
local fn = vim.fn
local tabnine_binary = require("tabnine.binary")
local utils = require("tabnine.utils")
local api = vim.api
local apply = require("tabnine.chat.apply")
local config = require("tabnine.config")
local lsp = require("tabnine.lsp")
local node_server = require("tabnine.node_server")

local M = { enabled = false }

local CHAT_STATE_FILE = utils.module_dir() .. "/chat_state.json"
local CHAT_SETTINGS_FILE = utils.module_dir() .. "/chat_settings.json"

local chat_state = nil
local chat_settings = nil
local initialized = false

local function to_chat_symbol_kind(kind)
	if kind == lsp.SYMBOL_KIND.METHOD then
		return "Method"
	elseif kind == lsp.SYMBOL_KIND.FUNCTION then
		return "Function"
	elseif kind == lsp.SYMBOL_KIND.CLASS then
		return "Class"
	elseif kind == lsp.SYMBOL_KIND.FILE then
		return "File"
	else
		return "Other"
	end
end
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
				enabledFeatures = vim.tbl_extend("force", response.enabled_features, { "chat_inline_completions" }),
			})
		end)
	end)

	chat_binary:register_event("workspace_folders", function(_, answer)
		answer({
			rootPaths = { fn.getcwd() },
		})
	end)

	chat_binary:register_event("get_server_url", function(request, answer)
		-- Call ChatCommunicatorAddress to trigger the Rust listener
		tabnine_binary:request({
			ChatCommunicatorAddress = { kind = request.kind },
		}, function(response)
			-- Ensure node-server is running
			node_server:ensure_running(function()
				local port = node_server:get_port()
				if port then
					local path = request.kind == "forward" and "/forward" or ""
					answer({
						serverUrl = "http://127.0.0.1:" .. port .. path,
					})
				else
					-- Fallback to response address if node-server not available
					answer({
						serverUrl = response.address,
					})
				end
			end)
		end)
	end)

	chat_binary:register_event("init", function(_, answer)
		local init = {
			ide = "nvim",
			isDarkTheme = vim.o.background == "dark",
			isSelfHosted = config.is_enterprise(),
		}
		if config.is_enterprise() then
			init.serverUrl = config.get_config().tabnine_enterprise_host
		end
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
		chat_state = chat_state or {}
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

	chat_binary:register_event("update_settings", function(settings, answer)
		chat_settings = settings
		write_chat_settings(settings)
		answer(nil)
	end)

	chat_binary:register_event("get_user", function(_, answer)
		tabnine_binary:request({ State = { dummy = true } }, function(state)
			answer({
				token = state.access_token,
				username = state.user_name,
				avatarUrl = state.user_avatar_url,
				serviceLevel = state.service_level,
				email = state.user_email,
				emailVerified = state.email_verified or false,
				subscriptions = state.subscriptions,
				team = state.team,
				allowedTeams = state.allowed_teams,
			})
		end)
	end)
	chat_binary:register_event("insert_at_cursor", function(message, answer)
		local lines = utils.str_to_lines(message.code)

		if message.diff then
			apply.open(message.diff, answer)
			return
		end

		api.nvim_buf_set_text(0, fn.line("v") - 1, fn.col("v") - 1, fn.line(".") - 1, fn.col(".") - 1, lines)
		answer({})
	end)

	chat_binary:register_event("get_basic_context", function(_, answer)
		tabnine_binary:request({
			FileMetadata = { path = vim.bo.filetype },
		}, function(metadata)
			answer({
				fileUri = api.nvim_buf_get_name(0),
				language = vim.bo.filetype,
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
					path = api.nvim_buf_get_name(0),
					currentLineIndex = api.nvim_win_get_cursor(0)[1] - 1,
				}
			elseif contextType == "Diagnostics" then
				return {
					type = "Diagnostics",
					diagnostics = get_diagnostics(),
				}
			elseif contextType == "Workspace" then
				return { type = "Workspace" } -- not implemented
			elseif contextType == "NFC" then
				-- TODO implement
				return nil
			else
				return nil
			end
		end, contextTypesSet)

		answer({ enrichingContextData = enrichingContextData })
	end)

	chat_binary:register_event("get_selected_code", function(_, answer)
		local selected_code = utils.selected_text()
		if selected_code and selected_code:len() > 0 then
			answer({
				code = selected_code,
				startLine = vim.fn.getpos("'<")[2],
				endLine = vim.fn.getpos("'>")[2],
				fileUri = api.nvim_buf_get_name(0),
			})
		else
			answer(nil)
		end
	end)

	chat_binary:register_event("get_symbols", function(request, answer)
		if not utils.buf_support_symbols() then
			answer({ workspaceSymbols = {}, documentSymbols = {} })
			return
		end
		lsp.get_document_symbols(request.query, function(document_symbols)
			lsp.get_workspace_symbols(request.query, function(workspace_symbols)
				answer({
					workspaceSymbols = vim.tbl_map(function(symbol)
						return {
							name = symbol.name,
							absolutePath = symbol.location.uri,
							relativePath = utils.remove_matching_prefix(symbol.location.uri, fn.getcwd()),
							kind = to_chat_symbol_kind(symbol.kind),
							range = {
								startLine = symbol.location.range.start.line,
								startCharacter = symbol.location.range.start.character,
								endLine = symbol.location.range["end"].line,
								endCharacter = symbol.location.range["end"].character,
							},
						}
					end, workspace_symbols),
					documentSymbols = vim.tbl_map(function(symbol)
						return {
							name = symbol.name,
							absolutePath = api.nvim_buf_get_name(0),
							relativePath = vim.fn.expand("%"),
							kind = to_chat_symbol_kind(symbol.kind),
							range = {
								startLine = symbol.range.start.line,
								startCharacter = symbol.range.start.character,
								endLine = symbol.range["end"].line,
								endCharacter = symbol.range["end"].character,
							},
						}
					end, document_symbols),
				})
			end)
		end)
	end)

	chat_binary:register_event("navigate_to_location", function(request, answer, error)
		if fn.filereadable(request.path) == 1 then
			local current_buffer_path = vim.fn.expand("%:p")
			local requested_path = fn.fnamemodify(request.path, ":p")

			if current_buffer_path ~= requested_path then
				vim.cmd("new " .. fn.fnameescape(request.path))
			else
				vim.cmd("buffer " .. fn.bufnr(request.path))
			end

			answer({})
		else
			error("File not found")
		end
	end)

	chat_binary:register_event("create_new_file", function(request, answer)
		fn.writefile({ "" }, request.path)
		answer({})
	end)

	chat_binary:register_event("get_file_content", function(request, answer, error)
		if vim.fn.filereadable(request.filePath) == 1 then
			local file_content = utils.lines_to_str(vim.fn.readfile(request.filePath))
			answer({ content = file_content })
		else
			error("File not found")
		end
	end)

	chat_binary:register_event("browse_folder", function(_, answer)
		vim.ui.input({
			prompt = "Select folder:\n",
			completion = "dir",
		}, function(path)
			answer({ path = path })
		end)
	end)

	chat_binary:register_event("browse_file", function(_, answer)
		vim.ui.input({
			prompt = "Select a file:\n",
			completion = "file",
		}, function(path)
			answer({ path = path, content = vim.fn.readfile(path) })
		end)
	end)

	chat_binary:register_event("browse_file_v2", function(_, answer)
		vim.ui.input({
			prompt = "Select an image:\n",
			completion = "file",
		}, function(path)
			path = vim.fn.expand(path)
			local mime_type = vim.fn.system("file --mime-type -b " .. vim.fn.shellescape(path)):gsub("%s+", "")
			local file_name = vim.fn.fnamemodify(path, ":t")
			local size_bytes = vim.fn.getfsize(path)
			local binary_content = vim.fn.readblob(path)
			local base64_content = vim.base64.encode(binary_content)
			answer({
				path = path,
				mimeType = mime_type,
				fileName = file_name,
				sizeBytes = size_bytes,
				base64Content = base64_content,
			})
		end)
	end)
	chat_binary:register_event("get_completions", function(request, answer)
		local file_extension = vim.fn.expand("%:e")
		tabnine_binary:request({
			Autocomplete = {
				filename = "tabnine-chat-input." .. file_extension,
				before = request.before,
				after = "",
				region_includes_beginning = false,
				region_includes_end = false,
				max_num_results = 1,
				offset = #request.before,
				line = 0,
				character = #request.before,
				indentation_size = 0,
				-- cached_only = false,
			},
		}, function(completion_results)
			if
				completion_results.results
				and completion_results.results[1]
				and completion_results.results[1].new_prefix
			then
				answer({ completions = { completion_results.results[1].new_prefix } })
			else
				answer({ completions = {} })
			end
		end)
	end)

	chat_binary:register_event("get_symbols_text", function(request, answer)
		answer({
			symbols = vim.tbl_map(function(symbol)
				local buf = utils.read_file_into_buffer(symbol.absolutePath)
				local text = utils.lines_to_str(
					api.nvim_buf_get_text(
						buf,
						symbol.range.startLine,
						symbol.range.startCharacter,
						symbol.range.endLine,
						symbol.range.endCharacter,
						{}
					)
				)
				api.nvim_buf_delete(buf, { force = true })
				return { id = symbol.id, snippet = text }
			end, request.symbols),
		})
	end)

	chat_binary:register_event("send_event", function(event)
		tabnine_binary:request({
			Event = { name = event.eventName, properties = event.properties },
		}, function() end)
	end)

	chat_binary:register_event("send_to_terminal", function(request, answer)
		answer({ response = fn.system(request.text) })
	end)

	chat_binary:register_event("delete_file", function(request, answer, error)
		local path = request.path
		if fn.filereadable(path) ~= 1 then
			error("FILE_DOES_NOT_EXIST")
			return
		end
		local result = fn.delete(path)
		if result == 0 then
			local buf = fn.bufnr(path)
			if buf ~= -1 and api.nvim_buf_is_loaded(buf) then
				api.nvim_buf_delete(buf, { force = true })
			end
			answer({})
		else
			error("Failed to delete file")
		end
	end)

	chat_binary:register_event("create_untitled_file", function(_, answer)
		vim.cmd("enew")
		answer({})
	end)

	chat_binary:register_event("insert_at_line", function(request, answer)
		local lines = utils.str_to_lines(request.code)
		local line_number = request.lineNumber or 0
		api.nvim_buf_set_lines(0, line_number, line_number, false, lines)
		vim.cmd("write")
		answer({})
	end)

	chat_binary:register_event("get_file_content_v2", function(request, answer, error)
		local path = request.filePath
		if fn.filereadable(path) ~= 1 then
			error("FILE_DOES_NOT_EXIST")
			return
		end
		local size_bytes = fn.getfsize(path)
		local max_size = 20 * 1024 * 1024
		if size_bytes > max_size then
			error("FILE_TOO_LARGE")
			return
		end
		local binary_content = fn.readblob(path)
		local base64_content = vim.base64.encode(binary_content)
		local mime_type = fn.system("file --mime-type -b " .. fn.shellescape(path)):gsub("%s+", "")
		local file_name = fn.fnamemodify(path, ":t")
		answer({
			path = path,
			mimeType = mime_type,
			fileName = file_name,
			sizeBytes = size_bytes,
			base64Content = base64_content,
		})
	end)

	chat_binary:register_event("resolve_symbols", function(request, answer)
		if not utils.buf_support_symbols() then
			answer(nil)
			return
		end
		lsp.get_workspace_symbols(request.symbol, function(symbols)
			local result = vim.tbl_map(function(symbol)
				local uri = symbol.location.uri
				local absolute_path = uri:gsub("^file://", "")
				local relative_path = utils.remove_matching_prefix(absolute_path, fn.getcwd() .. "/")
				local excluded_dirs = { "node_modules", "dist", "build", "target", "out" }
				for _, dir in ipairs(excluded_dirs) do
					if relative_path:find("^" .. dir) then
						return nil
					end
				end
				return {
					name = symbol.name,
					kind = symbol.kind,
					location = symbol.location,
					relativePath = relative_path,
				}
			end, symbols or {})
			result = vim.tbl_filter(function(s)
				return s ~= nil
			end, result)
			answer(result)
		end)
	end)

	chat_binary:register_event("peek_definition", function(request, answer)
		if request.symbols and #request.symbols == 1 then
			local symbol = request.symbols[1]
			if symbol.location then
				local uri = symbol.location.uri
				local path = uri:gsub("^file://", "")
				local range = symbol.location.range
				vim.cmd("edit " .. fn.fnameescape(path))
				if range and range.start then
					api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
				end
			end
		end
		answer({})
	end)

	chat_binary:register_event("get_folding_ranges", function(_, answer)
		local ranges = {}
		local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
		if ok then
			local node = ts_utils.get_node_at_cursor()
			while node do
				local start_row, _, end_row, _ = node:range()
				local lines = api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
				local code = table.concat(lines, "\n")
				table.insert(ranges, { code = code })
				node = node:parent()
			end
		end
		answer({ ranges = ranges })
	end)

	chat_binary:register_event("login", function(_, answer)
		vim.cmd("TabnineLogin")
		answer({})
	end)

	chat_binary:register_event("git_diff", function(request, answer, error)
		tabnine_binary:request({
			GitDiff = {
				diff_type = request.diff_type,
				repository_path = request.repository_path or fn.getcwd(),
			},
		}, function(response)
			if response then
				answer(response)
			else
				error("Failed to get git diff")
			end
		end)
	end)

	chat_binary:register_event("git_repository_metadata", function(request, answer, error)
		tabnine_binary:request({
			GitRepositoryMetadata = {
				repository_path = request.repository_path or fn.getcwd(),
			},
		}, function(response)
			if response then
				answer(response)
			else
				error("Failed to get git repository metadata")
			end
		end)
	end)

	chat_binary:register_event("resolve_diff", function(request, answer)
		if request.accepted then
			apply.accept()
		else
			apply.reject()
		end
		answer({ success = true })
	end)

	chat_binary:register_event("get_diagnostics", function(request, answer)
		local path = request.filePath
		local buf = fn.bufnr(path)
		local with_warnings = request.withWarnings or false

		local diagnostics_list = {}
		if buf ~= -1 then
			local all_diagnostics = vim.diagnostic.get(buf)
			for _, diagnostic in ipairs(all_diagnostics) do
				local severity = diagnostic.severity
				local include = severity == vim.diagnostic.severity.ERROR
				if with_warnings then
					include = include or severity == vim.diagnostic.severity.WARN
				end
				if include then
					local line_code = ""
					if api.nvim_buf_is_loaded(buf) then
						local lines = api.nvim_buf_get_lines(buf, diagnostic.lnum, diagnostic.lnum + 1, false)
						line_code = lines[1] or ""
					end
					table.insert(diagnostics_list, {
						errorMessage = diagnostic.message,
						lineCode = line_code,
						lineNumber = diagnostic.lnum + 1,
						level = severity == vim.diagnostic.severity.ERROR and "Error" or "Warning",
					})
				end
			end
		end
		answer({ diagnostics = diagnostics_list })
	end)

	chat_binary:register_event("do_fetch", function(request, answer)
		local input = request.input
		local init = request.initWithTimeout or {}
		local method = init.method or "GET"
		local headers = init.headers or {}
		local body = init.body
		local timeout = init.timeout or 30000

		local curl_args = { "curl", "-s", "-S", "-w", "\n%{http_code}", "--max-time", tostring(timeout / 1000) }

		for key, value in pairs(headers) do
			table.insert(curl_args, "-H")
			table.insert(curl_args, key .. ": " .. value)
		end

		if method ~= "GET" then
			table.insert(curl_args, "-X")
			table.insert(curl_args, method)
		end

		if body then
			table.insert(curl_args, "-d")
			table.insert(curl_args, body)
		end

		table.insert(curl_args, input)

		local result = fn.system(curl_args)
		local lines = vim.split(result, "\n")
		local status_code = tonumber(lines[#lines]) or 0
		table.remove(lines)
		local response_body = table.concat(lines, "\n")

		answer({
			status = status_code,
			statusText = status_code >= 200 and status_code < 300 and "OK" or "Error",
			headers = {},
			body = response_body,
			ok = status_code >= 200 and status_code < 300,
		})
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
			"tabnine_webview binary not found, did you remember to build it first? `cargo build --release` inside `webview/` directory"
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

local utils = require("tabnine.utils")

local M = {}

local node_server_port = nil
local rust_server_port = nil
local initialized = false

local function find_port_sync()
	local port = nil
	utils.find_free_port(function(p)
		port = p
	end)
	return port
end

function M.init()
	if initialized then
		return
	end

	node_server_port = find_port_sync()
	rust_server_port = find_port_sync()

	if node_server_port then
		vim.env.NODE_SERVER_PORT = tostring(node_server_port)
	end

	if rust_server_port then
		vim.env.RUST_SERVER_PORT = tostring(rust_server_port)
	end

	initialized = true
end

function M.get_node_server_port()
	return node_server_port
end

function M.get_rust_server_port()
	return rust_server_port
end

function M.is_initialized()
	return initialized
end

return M

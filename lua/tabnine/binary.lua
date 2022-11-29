local uv = vim.loop
local fn = vim.fn
local json = vim.json
local utils = require('tabnine.utils')
local M = {}

json.encode_empty_table_as_object(true)
local requests_counter = 0;
-- TODO order by semver
local tabnine_binary_path =
    "/home/amir/Workspace/tabnine-nvim/binaries/4.4.24/x86_64-unknown-linux-musl/TabNine";
local stdin = uv.new_pipe()
local stdout = uv.new_pipe()
local stderr = uv.new_pipe()
local callbacks = {}

local _, _ = uv.spawn(tabnine_binary_path, {
    args = {'--client', 'vscode'},
    stdio = {stdin, stdout, stderr}
}, function() print("process existed") end)

uv.read_start(stdout, function(error, chunk)
    if chunk then
        vim.schedule(function()
            for _, line in pairs(utils.str_to_lines(chunk)) do
                for _, callback in pairs(callbacks) do
                    callback(json.decode(line))
                end
            end
        end)
    elseif error then
        print("read_start error", error)
    end
end)

function M.on_response(callback) table.insert(callbacks, callback) end

function M.request(request)
    uv.write(stdin, json.encode({request = request, version = "1.1.1"}) .. "\n")
end

return M;

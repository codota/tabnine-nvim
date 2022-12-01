local uv = vim.loop
local fn = vim.fn
local json = vim.json
local utils = require('tabnine.utils')
local semver = require('tabnine.third_party.semver.semver')
local M = {}

json.encode_empty_table_as_object(true)

local binaries_path = utils.script_path() .. '../../binaries'

local function arch_and_platform()
    local os_uname = uv.os_uname();

    if os_uname.sysname == "Linux" and os_uname.machine == "x86_64" then
        return 'x86_64-unknown-linux-musl'
    elseif os_uname.sysname == "Darwin" and os_uname.machine == "arm64" then
        return 'aarch64-apple-darwin'
    elseif fn.has('win32') then
        return 'windows-gnu'
    end

end

local function binary_path()
    local paths = vim.tbl_map(function(path)
        return fn.fnamemodify(path, ":t")
    end, fn.glob(binaries_path .. '/*', true, true))

    paths = vim.tbl_map(function(path) return semver(path) end, paths)

    table.sort(paths)

    return binaries_path .. '/' .. tostring(paths[#paths]) .. '/' ..
               arch_and_platform() .. '/TabNine'
end

local stdin = uv.new_pipe()
local stdout = uv.new_pipe()
local stderr = uv.new_pipe()
local callbacks = {}
local restart_counter = 0
local handle, pid

local function start()
    handle, pid = uv.spawn(binary_path(), {
        args = {
            '--client', 'nvim', '--client-metadata',
            'ide-restart-counter=' .. restart_counter
        },
        stdio = {stdin, stdout, stderr}
    }, function()
        handle, pid = nil, nil
        uv.read_stop(stdout)
    end)

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

end

function M.on_response(callback) table.insert(callbacks, callback) end

function M.request(request)
    if not pid then
        restart_counter = restart_counter + 1
        start()
    end
    uv.write(stdin, json.encode({request = request, version = "1.1.1"}) .. "\n")
end

return M;

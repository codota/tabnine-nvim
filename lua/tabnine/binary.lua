local uv = vim.loop
local fn = vim.fn
local M = {}

-- TODO order by semver
local tabnine_binary_path =
    "/home/amir/Workspace/tabnine-nvim/binaries/4.4.24/x86_64-unknown-linux-musl/TabNine";
local stdin = uv.new_pipe()
local stdout = uv.new_pipe()
local stderr = uv.new_pipe()

local _, _ = uv.spawn(tabnine_binary_path, {
    args = {'--client', 'vscode'},
    stdio = {stdin, stdout, stderr}
}, function() print("process existed") end)

function M.on_response(callback)
    uv.read_start(stdout, function(error, chunk)
        if chunk then
            -- may need to split by lines
            vim.schedule(function() callback(fn.json_decode(chunk)) end)
        elseif error then
            print("read_start error", error)
        end
    end)

end

function M.request(request)
    uv.write(stdin,
             fn.json_encode({request = request, version = "1.1.1"}) .. "\n")
end

return M;

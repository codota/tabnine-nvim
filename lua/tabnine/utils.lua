local fn = vim.fn

local M = {}

function M.debounce_trailing(fn, ms, first)
    local timer = vim.loop.new_timer()
    local wrapped_fn

    if not first then
        function wrapped_fn(...)
            local argv = {...}
            local argc = select('#', ...)

            timer:start(ms, 0, function()
                pcall(vim.schedule_wrap(fn), unpack(argv, 1, argc))
            end)
        end
    else
        local argv, argc
        function wrapped_fn(...)
            argv = argv or {...}
            argc = argc or select('#', ...)

            timer:start(ms, 0, function()
                pcall(vim.schedule_wrap(fn), unpack(argv, 1, argc))
            end)
        end
    end
    return wrapped_fn, timer
end

function M.str_to_lines(str) return fn.split(str, '\n') end

function M.remove_matching_suffix(str, suffix)
    if suffix == "" then return str end
    if (str:sub(-#suffix) == suffix) then return str:sub(1, -#suffix - 1) end
    return str
end

function M.fif(condition, if_true, if_false)
    if condition then
        return if_true
    else
        return if_false
    end
end

function M.subset(tbl, from, to) return {unpack(tbl, from, to)} end

function M.script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

function M.prequire(...)
    local status, lib = pcall(require, ...)
    if status then return lib end
    return nil
end

function M.pumvisible()
    local cmp = M.prequire("cmp")
    if cmp then
        return cmp.visible()
    else
        return vim.fn.pumvisible() > 0
    end
end

return M

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

function M.str_to_lines(str)
    -- local result = {}
    -- for line in str:gmatch '[^\n]+' do table.insert(result, line) end
    -- return result
    return fn.split(str, '\n')
end

function M.fif(condition, if_true, if_false)
    if condition then
        return if_true
    else
        return if_false
    end
end

function M.map(tbl, f)
    local t = {}
    for k, v in pairs(tbl) do t[k] = f(v) end
    return t
end

function M.subset(tbl, from, to) return {unpack(tbl, from, to)} end

return M

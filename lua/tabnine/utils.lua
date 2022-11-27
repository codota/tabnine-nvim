local M = {}

---Validates args for `throttle()` and  `debounce()`.
local function td_validate(fn, ms)
    vim.validate {
        fn = {fn, 'f'},
        ms = {
            ms, function(ms) return type(ms) == 'number' and ms > 0 end,
            "number > 0"
        }
    }
end

function M.debounce_trailing(fn, ms, first)
    print("here!")
    td_validate(fn, ms)
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
return M

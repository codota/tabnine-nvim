local api = vim.api
local fn = vim.fn

local tabnine = {}
local tabnine_binary = require('tabnine.binary')
local utils = require('tabnine.utils')

MAX_CHARS = 3000;
current_position = {}
requests_counter = 0
last_response = {}
local function complete()
    current_position = api.nvim_win_get_cursor(0)
    local before_table = api.nvim_buf_get_text(0, 0, 0, current_position[1] - 1,
                                               current_position[2] - 1, {})
    local before = table.concat(before_table, "\n")

    tabnine_binary.request({
        Autocomplete = {
            before = before,
            after = "",
            filename = "test.ts",
            region_includes_beginning = true,
            region_includes_end = false,
            max_num_results = 1,
            correlation_id = requests_counter
        }
    })

    requests_counter = requests_counter + 1
end

local function accept()
    if last_response then
        api.nvim_buf_set_text(0, current_position[1] - 1, current_position[2],
                              current_position[1] - 1, current_position[2],
                              last_response)
    end

end

local function hub() tabnine_binary.request({Configuration = {quiet = false}}) end

-- move to utils or something
local function lines(str)
    local result = {}
    for line in str:gmatch '[^\n]+' do table.insert(result, line) end
    return result
end

function tabnine.setup()
    local ns = api.nvim_create_namespace('tabnine')
    d = utils.debounce_trailing(complete, 300, false)
    api.nvim_create_autocmd("TextChangedI", {
        pattern = "*",
        callback = function()
            api.nvim_buf_clear_namespace(0, ns, 0, -1)
            d()
        end
    })

    api.nvim_create_user_command("TabnineHub", hub, {})

    api.nvim_set_keymap("i", "<Tab>", "", {
        callback = function()
            api.nvim_buf_clear_namespace(0, ns, 0, -1)
            accept()
        end
    })

    tabnine_binary.on_response(function(response)
        last_response = nil
        if response.results[1] then
            last_response = lines(response.results[1].new_prefix)
            local snippet = lines(response.results[1].new_prefix)
            local first_line = {
                response.old_prefix ~= "" and
                    string.sub(snippet[1], string.len(response.old_prefix) + 2,
                               -1) or snippet[1], 'LineNr'
            }
            local rest = {}
            if snippet[2] then
                table.remove(snippet, 1)
                for i, line in pairs(snippet) do
                    print("line", line)
                    rest[i] = {line, 'LineNr'}
                end
            end

            api.nvim_buf_set_extmark(0, ns, current_position[1] - 1,
                                     current_position[2], {
                virt_text = {first_line},
                virt_text_pos = "overlay",
                virt_lines = {rest}
            })
        end

    end)
end

return tabnine


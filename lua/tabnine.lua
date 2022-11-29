local api = vim.api
local fn = vim.fn
local tabnine_binary = require('tabnine.binary')
local utils = require('tabnine.utils')

local M = {}
MAX_CHARS = 3000;
local tabnine_ns = 0
local requests_counter = 0
local current_completion = {}

local function auto_complete_response(response)
    if response.results and response.results[1] and
        #response.results[1].new_prefix > 0 then
        current_completion = utils.str_to_lines(response.results[1].new_prefix)
        current_completion[1] = utils.fif(#response.old_prefix > 0, string.sub(
                                              current_completion[1],
                                              #response.old_prefix + 1, -1),
                                          current_completion[1])

        local first_line = {{current_completion[1], 'LineNr'}}
        local other_lines = utils.map(utils.subset(current_completion, 2),
                                      function(line)
            return {{line, 'LineNr'}}
        end)

        api.nvim_buf_set_extmark(0, tabnine_ns, fn.line(".") - 1,
                                 fn.col(".") - 1, {
            virt_text = first_line,
            virt_text_pos = "overlay",
            virt_lines = other_lines
        })
    end

end

local function auto_complete_request()
    local before_table = api.nvim_buf_get_text(0, 0, 0, fn.line(".") - 1,
                                               fn.col(".") - 1, {})
    local before = table.concat(before_table, "\n")

    tabnine_binary.request({
        Autocomplete = {
            before = before,
            after = "",
            filename = fn.expand("%:t"),
            region_includes_beginning = true,
            region_includes_end = false,
            max_num_results = 1,
            correlation_id = requests_counter
        }
    })

end

local function accept()
    if current_completion then
        api.nvim_buf_set_text(0, fn.line(".") - 1, fn.col(".") - 1,
                              fn.line(".") - 1, fn.col(".") - 1,
                              current_completion)

        api.nvim_win_set_cursor(0, {
            fn.line("."), fn.col(".") + #current_completion[#current_completion]
        })

        current_completion = nil
    end
end

local function hub() tabnine_binary.request({Configuration = {quiet = false}}) end

function M.setup()

    tabnine_binary.on_response(auto_complete_response)

    local debounced_auto_complete_request =
        utils.debounce_trailing(auto_complete_request, 300, false)

    api.nvim_create_autocmd("TextChangedI", {
        pattern = "*",
        callback = function()
            tabnine_ns = api.nvim_create_namespace('tabnine')
            api.nvim_buf_clear_namespace(0, tabnine_ns, 0, -1)
            debounced_auto_complete_request()
        end
    })

    api.nvim_create_user_command("TabnineHub", hub, {})

    api.nvim_set_keymap("i", "<Tab>", "", {
        callback = function()
            accept()
            api.nvim_buf_clear_namespace(0, tabnine_ns, 0, -1)
        end
    })

end

return M


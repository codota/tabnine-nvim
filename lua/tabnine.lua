local api = vim.api
local uv = vim.loop
local fn = vim.fn
local TabnineBinary = require('tabnine.binary')
local utils = require('tabnine.utils')

local M = {}
local plugin_version = "0.0.1"
local max_chars = 3000
local tabnine_namespace = 0
local requests_counter = 0
local current_completion = nil
local service_level = nil
local tabnine_binary = TabnineBinary:new({plugin_version = plugin_version})

local function auto_complete_response(response)
    if response.results and response.results[1] and
        #response.results[1].new_prefix > 0 then
        current_completion = utils.str_to_lines(response.results[1].new_prefix)
        current_completion[1] = utils.fif(#response.old_prefix > 0,
                                          current_completion[1]:sub(
                                              #response.old_prefix + 1, -1),
                                          current_completion[1])

        local first_line = {{current_completion[1], 'LineNr'}}
        local other_lines = vim.tbl_map(function(line)
            return {{line, 'LineNr'}}
        end, utils.subset(current_completion, 2))

        api.nvim_buf_set_extmark(0, tabnine_namespace, fn.line(".") - 1,
                                 fn.col(".") - 1, {
            virt_text_win_col = fn.virtcol('.') - 1,
            hl_mode = "combine",
            virt_text = first_line,
            virt_lines = other_lines
        })
    end

end

local function poll_service_level()
    local timer = uv.new_timer()
    timer:start(0, 5000, function()
        vim.schedule(function() tabnine_binary:request({State = {}}) end)
    end)
end

local function dispatch_binary_responses()
    tabnine_binary:on_response(function(response)
        if response.results and response.results[1] and
            #response.results[1].new_prefix > 0 then
            auto_complete_response(response)
        elseif response.service_level then
            service_level = response.service_level
        end
    end)
end

local function bind_to_document_changed()
    local function auto_complete_request()
        local before_table = api.nvim_buf_get_text(0, 0, 0, fn.line(".") - 1,
                                                   fn.col(".") - 1, {})
        local before = table.concat(before_table, "\n")

        tabnine_binary:request({
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

    local debounced_auto_complete_request =
        utils.debounce_trailing(auto_complete_request, 300, false)

    api.nvim_create_autocmd("TextChangedI", {
        pattern = "*",
        callback = function()
            tabnine_namespace = api.nvim_create_namespace('tabnine')
            api.nvim_buf_clear_namespace(0, tabnine_namespace, 0, -1)
            debounced_auto_complete_request()
        end
    })

end

local function bind_to_accept(accept_keymap)
    local function accept()
        if current_completion then
            api.nvim_buf_set_text(0, fn.line(".") - 1, fn.col(".") - 1,
                                  fn.line(".") - 1, fn.col(".") - 1,
                                  current_completion)

            api.nvim_win_set_cursor(0, {
                fn.line("."),
                fn.col(".") + #current_completion[#current_completion]
            })

            current_completion = nil
        end
    end

    api.nvim_set_keymap("i", accept_keymap, "", {
        noremap = true,
        callback = function()
            accept()
            api.nvim_buf_clear_namespace(0, tabnine_namespace, 0, -1)
        end
    })

end

local function create_user_commands()
    api.nvim_create_user_command("TabnineHub", function()
        tabnine_binary:request({Configuration = {}})
    end, {})
end

function M.service_level() return service_level end

function M.setup(config)
    config = vim.tbl_extend("force", {
        disable_auto_comment = false,
        accept_keymap = "<Tab>"
    }, config or {})

    dispatch_binary_responses()

    poll_service_level()

    bind_to_document_changed()

    bind_to_accept(config.accept_keymap)

    create_user_commands()

    api.nvim_create_autocmd("ModeChanged", {
        pattern = "*",
        callback = function()
            api.nvim_buf_clear_namespace(0, tabnine_namespace, 0, -1)
        end
    })

    if config.disable_auto_comment then
        api.nvim_create_autocmd('FileType', {
            pattern = '*',
            command = 'setlocal formatoptions-=c formatoptions-=r formatoptions-=o'
        })
    end

end

return M


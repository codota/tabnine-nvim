if vim.g.loaded_tabnine_plugin then
    return
end
vim.g.loaded_tabnine_plugin = true

-- Initialize ports before any binaries are started
require("tabnine.ports").init()


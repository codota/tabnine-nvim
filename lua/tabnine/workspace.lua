local tabnine_binary = require("tabnine.binary")
local uv = vim.uv or vim.loop
local lsp = vim.lsp
local config = require("tabnine.config")
local utils = require("tabnine.utils")

local M = {}

local function workspace_folders()
  local config = config.get_config().workspace_folders
  local lsp_folders = {}

  if config.lsp and #utils.buf_get_clients() > 0 then lsp_folders = utils.set(lsp.buf.list_workspace_folders()) end

  return vim.tbl_extend("keep", lsp_folders, config.paths or {}, config.get_paths and config.get_paths() or {})
end

function M.update()
  tabnine_binary:request({ Workspace = { root_paths = workspace_folders() } }, function() end)
end

function M.setup()
  local timer = uv.new_timer()

  timer:start(0, 30000, vim.schedule_wrap(M.update))
end

return M

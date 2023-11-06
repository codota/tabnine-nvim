--- This file is for lazy.nvim's build.lua support.
local build = require("tabnine.build")
--- If this file is run through `require()` then it `...` will be the module path
--- If run through `:source` (lazy.nvim) or `dofile()` (manually), it will be `nil`
if ... == nil then return build.run_build() end

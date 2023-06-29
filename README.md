# tabnine-nvim

Tabnine client for Neovim

![Tabnine Neovim client](https://github.com/codota/tabnine-nvim/blob/master/examples/javascript.gif)

## Install

**Note** this plugin requires having [Neovim](https://github.com/neovim/neovim) version >= v0.7

The _Unix_ build script requires `curl` and `unzip` to be available in your `$PATH`

### Unix (Linux, MacOS)

Using [vim-plug](https://github.com/junegunn/vim-plug)

1. Add the following in your `init.vim`

```vim
call plug#begin()
Plug 'codota/tabnine-nvim', { 'do': './dl_binaries.sh' }
call plug#end()
```

2. Restart Neovim and run `:PlugInstall`

Using [packer](https://github.com/wbthomason/packer.nvim)

1. Add the following in your `init.lua`:

```lua
require("packer").startup(function(use)
  use { 'codota/tabnine-nvim', run = "./dl_binaries.sh" }
end)
```

2. Restart Neovim and run `:PackerInstall`

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

1. Add the following in your `init.lua`:

```lua
require("lazy").setup({
  { 'codota/tabnine-nvim', build = "./dl_binaries.sh" },
})
```

2. Restart Neovim and run `:Lazy`

### Windows

<!-- > **Note:**
> For Please see below for Windows installation instructions -->

The build script needs a set execution policy.
Here is an example on how to set it

```Powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

For more information visit
[the official documentation](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.2)

Windows installations need to be adjusted to utilize PowerShell. This can be accomplished by changing the `do`/`run`/`build` parameter in your plugin manager's configuration from `./dl_binaries.sh` to `pwsh.exe -file .\\dl_binaries.ps1`

```Lua
-- Example using lazy.nvim
-- pwsh.exe for PowerShell Core
-- powershell.exe for Windows PowerShell

require("lazy").setup({
  { 'codota/tabnine-nvim', build = "pwsh.exe -file .\\dl_binaries.ps1" },
})
```

If you need to use Tabnine on Windows and Unix you can change the config as follows

```lua
-- Get platform dependant build script
local function tabnine_build_path()
  if vim.loop.os_uname().sysname == "Windows_NT" then
    return "pwsh.exe -file .\\dl_binaries.ps1"
  else
    return "./dl_binaries.sh"
  end
end
require("lazy").setup({
  { 'codota/tabnine-nvim', build = tabnine_build_path()},
})
```

---

## Activate (mandatory)

Add this later in your `init.lua`:

```lua
require('tabnine').setup({
  disable_auto_comment=true,
  accept_keymap="<Tab>",
  dismiss_keymap = "<C-]>",
  debounce_ms = 800,
  suggestion_color = {gui = "#808080", cterm = 244},
  exclude_filetypes = {"TelescopePrompt"},
  log_file_path = nil, -- absolute path to Tabnine log file
})
```

`init.vim` users - the activation script is `lua` code. Make sure to have it inside `lua` block:

```vim
lua <<EOF
" activate tabnine here
EOF
```
## Tabnine Chat - still in ALPHA
To use Tabnine Chat - you will need to first build it under `chat/` directory using `cargo build --release`, then run `:TabnineChat`

## Activate Tabnine Pro

`:TabnineHub` - to open Tabnine Hub and log in to your account

Sometimes Tabnine may fail to open the browser on Tabnine Hub, in this case use `:TabnineHubUrl` to get Tabnine Hub URL

## Commands

- `:TabnineStatus` - to print Tabnine status
- `:TabnineDisable` - to disable Tabnine
- `:TabnineEnable` - to enable Tabnine
- `:TabnineToggle` - to toggle enable/disable

## `<Tab>` and `nvim-cmp`

`nvim-cmp` maps `<Tab>` to navigating through pop menu items (see [here](https://github.com/hrsh7th/nvim-cmp/blob/777450fd0ae289463a14481673e26246b5e38bf2/lua/cmp/config/mapping.lua#L86)) This conflicts with Tabnine `<Tab>` for inline completion. To get this sorted you can either:

- Bind Tabnine inline completion to a different key using `accept_keymap`
- Bind `cmp.select_next_item()` & `cmp.select_prev_item()` to different keys, e.g: `<C-k>` & `<C-j>`

## lualine integration

This plugin exposes a lualine `tabnine` component. e.g:

```lua
require('lualine').setup({
    tabline = {
        lualine_a = {},
        lualine_b = {'branch'},
        lualine_c = {'filename'},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
    },
    sections = {lualine_c = {'lsp_progress'}, lualine_x = {'tabnine'}}
})
```

## Other statusline integrations

To render tabnine status widget use:

```lua
require('tabnine.status').status()
```

## Tabnine Enterprise customers (self hosted only)

In your `init.lua`:

_these instructions are made for packer, but are pretty much the same with all package managers_

```lua
local tabnine_enterprise_host = "https://tabnine.customer.com"

require("packer").startup(function(use)
  use { 'codota/tabnine-nvim', run = "./dl_binaries.sh " .. tabnine_enterprise_host .. "/update" }
end)

require('tabnine').setup({
  disable_auto_comment=true,
  accept_keymap="<Tab>",
  dismiss_keymap = "<C-]>",
  debounce_ms = 800,
  suggestion_color = {gui = "#808080", cterm = 244},
  exclude_filetypes = {"TelescopePrompt"},
  log_file_path = nil, -- absolute path to Tabnine log file,
  tabnine_enterprise_host = tabnine_enterprise_host
})
```


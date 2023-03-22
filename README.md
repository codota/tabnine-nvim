# tabnine-nvim

Tabnine client for neovim

![Tabnine neovim client](https://github.com/codota/tabnine-nvim/blob/master/examples/javascript.gif)

## Install

### Unix (Linux, MacOS)

Using [vimplug](https://github.com/junegunn/vim-plug)

1. Add the following in your `init.vim`

```vim
call plug#begin()
Plug 'codota/tabnine-nvim', { 'do': './dl_binaries.sh' }
call plug#end()
```

2. Restart neovim and run `:PluginInstall`

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

---

## Activate (mandatory)

add this later in your `init.lua`:

```lua
require('tabnine').setup({
  disable_auto_comment=true,
  accept_keymap="<Tab>",
  dismiss_keymap = "<C-]>",
  debounce_ms = 800,
  suggestion_color = {gui = "#808080", cterm = 244},
  exclude_filetypes = {"TelescopePrompt"}
})
```

`init.vim` users - the activation script is `lua` code. make sure to have it inside `lua` block. e.g:

```vim
lua <<EOF
" activate tabnine here
EOF
```

## Activate Tabnine Pro

`:TabnineHub` - to open Tabnine Hub and log in to your account

Sometimes Tabnine may fail to open the browser on Tabnine Hub, in this case use `:TabnineHubUrl` to get Tabnine Hub url

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

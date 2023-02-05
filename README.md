__Note:__ We've recently made a huge refactor - still in BETA. check out our [beta](https://github.com/codota/tabnine-nvim/tree/beta) branch and share your feedback [here](https://github.com/codota/tabnine-nvim/issues/26)

# tabnine-nvim

Tabnine client for neovim

![Tabnine neovim client](https://github.com/codota/tabnine-nvim/blob/master/expamples/javascript.gif)

## Install

Using [vimplug](https://github.com/junegunn/vim-plug)

```
Plug 'codota/tabnine-nvim', { 'do': './dl_binaries.sh' }
```

Using [packer](https://github.com/wbthomason/packer.nvim)
```lua
  use { 'codota/tabnine-nvim', run = "./dl_binaries.sh" }
```

Basic configuration activation:
```lua
require('tabnine').setup({
  disable_auto_comment=true,
  accept_keymap="<Tab>",
  dismiss_keymap = "<C-]>",
  debounce_ms = 800,
  suggestion_color = {gui = "#808080", cterm = 244},
  execlude_filetypes = {"TelescopePrompt"}
})
```



## Activate Tabnine Pro

`:TabnineHub` - to open Tabnine Hub and log in to your account

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

## Known issues

Windows isn't supported yet. PRs are welcome!


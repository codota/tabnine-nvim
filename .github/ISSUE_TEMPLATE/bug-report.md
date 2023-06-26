---
name: Bug report
about: Create a report to help us improve
title: "[BUG]"
labels: ""
assignees: ""
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:

1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Version Info:**

- OS (try `cat /etc/os-release`):
- Neovim version (`nvim -v`):
- Installed Tabnine Binaries (`ls -A /path/to/plugin/binaries`):
- Active Tabnine Binaries (`cat /path/to/plugin/binaries/.active`):

<!--
This command will usually list all the Tabnine versions, as well as the active one:
```shell
> ls -A -- "$(nvim --headless -c 'lua io.stdout:write(vim.fn.stdpath("data"))' -c qa)"/*/tabnine-nvim/binaries/
> cat -- "$(nvim --headless -c 'lua io.stdout:write(vim.fn.stdpath("data"))' -c qa)"/*/tabnine-nvim/binaries/.active
```
-->

**Additional context**
Add any other context about the problem here.

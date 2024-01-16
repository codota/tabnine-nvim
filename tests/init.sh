#!/usr/bin/env bash
# Run this script to test the module. Any file in this directory matching *_spec.lua will be run.
# See https://github.com/nvim-lua/plenary.nvim?tab=readme-ov-file#plenarytest_harness for more information
set -euC -o pipefail

# This is a lua table of options
read -r -d '' OPTIONS <<'EOF' || true
{
  minimal_init = "None", -- Required to avoid errors with package.path in user's init.lua
  sequential = false, -- Run in parallel if false
}
EOF

# Some utilities
log() { printf '%s\n' "$@" || true; }
err() { printf '%s\n' "$@" >&2 || true; }
abort() { err "$1" && exit "${2:-1}"; }
verbose() { log "> ${*@Q}" && "$@"; }

# Get the script's directory. This is the /tests dir
this_dir=.
if [ -f "${0:-}" ]; then this_dir=$(dirname -- "$0"); fi
case "$this_dir" in
*" "*) # contains a space! This can't work!
  err "PlenaryBustedDirectory can't handle directories with spaces."
  err "changing current directory to ${this_dir@Q}."
  cd "$this_dir" || abort "Could not change directory!" "$?"
  this_dir=.
  ;;
esac

# Either 'true' or 'false' -- note: parens are imporant to ensure that only the first value is returned
has_plenary=$(nvim --headless -c 'lua =(pcall(require,"plenary"))' -c 0cq 2>&1)
[ "$has_plenary" = true ] || abort "Could not find plenary module! Please install from https://github.com/nvim-lua/plenary.nvim." 1

exec nvim --headless -c "PlenaryBustedDirectory $this_dir ${OPTIONS:-}"

<!-- Note: this file is meant for contributors, not users. -->

# tabnine-nvim tests

Run `./init.sh` to test the module. (requires `bash`)
Any file in this directory matching `*_spec.lua` will be run.

- See the [plenary readme](https://github.com/nvim-lua/plenary.nvim?tab=readme-ov-file#plenarytest_harness) for more information

## Examples

See the following links for examples

- [busted docs](https://lunarmodules.github.io/busted/#asserts)
- [nvim-lua/plenary.nvim README](https://github.com/nvim-lua/plenary.nvim?tab=readme-ov-file#plenarytest_harness)
- [plenary tests examples](https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md)
- [luaassert readme](https://github.com/lunarmodules/luassert)
- [busted readme](https://github.com/lunarmodules/busted)
  - Note: not all busted examples will work. plenary implements a busted-_like_ interface. See [plenary's readme](https://github.com/nvim-lua/plenary.nvim?tab=readme-ov-file#plenarytest_harness) for more information

### Some useful assert functions

This is _not_ a comprehensive list. See the [busted docs](https://lunarmodules.github.io/busted/#asserts) and the [luaassert readme](https://github.com/lunarmodules/luassert) for the complete docs

- ref(one, two) -- check if two objects are the same (by reference)
- same(one, two) -- check if two values are the same (by value, recursively)
- matches(val, pat) -- check if a string value matches a pattern (same as `assert(value:find(pattern, init, plain))`)
- near(one, two, tolerance) -- Check if a number is within a given tolerance of another number
- equals(one, two) -- check if `one == two`
- unique(value_list, deep) -- check that all the values in the list are unique
- truthy(value) -- checks that the value is not `nil` or `false`
- falsy(value) -- check that the value is `nil` or `false`
- is_TYPE(value) -- check that the value is of type TYPE
  - is_true, is_false, is_nil, is_boolean, is_number, is_string, is_table, is_function, is_userdata, and is_thread

Note: you can use `assert.is_not.whatever` to negate an assertion

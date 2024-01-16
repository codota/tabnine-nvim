--- See the following links for examples
-- https://github.com/nvim-lua/plenary.nvim?tab=readme-ov-file#plenarytest_harness
-- https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md
-- https://github.com/lunarmodules/luassert
-- https://github.com/lunarmodules/busted
---- Note: not all busted examples will work. plenary implements a busted-*like* interface.

--- Some useful assert functions:
--- is_true, is_false, is_nil, is_boolean, is_number, is_string, is_table, is_function, is_userdata, is_thread
--- ref, same, matches, matches, near, equals, equals, unique, truthy, falsy
local busted = require("plenary.busted")
local describe, it = busted.describe, busted.it
local assert = require("luassert")

describe("testing framework", function()
	it("should run tests", function()
		assert.truthy(true)
	end)
end)

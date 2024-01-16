local busted = require("plenary.busted")
local describe, it = busted.describe, busted.it
local assert = require("luassert")

describe("testing framework", function()
	it("should run tests", function()
		assert.truthy(true)
	end)
end)

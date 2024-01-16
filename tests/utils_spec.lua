local assert = require("luassert")
local utils = require("tabnine.utils")
local eq = assert.same
table.pack, table.unpack = table.pack or vim.F.pack_len, table.unpack or unpack
--- Creates a wrapper that calls f with given args
--- use like: assert.error(wrap(f, 1, 3, 4), "error: here")
local function wrap(f, ...)
	local args = table.pack(...)
	return function()
		return f(table.unpack(args, 1, args.n))
	end
end

describe("utils", function()
	pending("debounce", function()
		-- utils.debounce(func, delay)
	end)

	describe("str_to_lines", function()
		it("splits on newlines", function()
			local lines = utils.str_to_lines("Hello\nworld")
			eq({ "Hello", "world" }, lines)
		end)
		--- TODO: Should it? This is different than lines_to_str
		it("trims leading and trailing newlines", function()
			local lines = utils.str_to_lines("\nHello\nworld\n")
			eq({ "Hello", "world" }, lines)
		end)
		it("includes empty lines", function()
			local lines = utils.str_to_lines("Hello\n\nworld")
			eq({ "Hello", "", "world" }, lines)
		end)
		it("includes consecutive empty lines", function()
			local lines = utils.str_to_lines("Hello\n\n\n\n\nworld")
			eq({ "Hello", "", "", "", "", "world" }, lines)
		end)
	end)

	describe("lines_to_str", function()
		it("joins on newlines", function()
			local str = utils.lines_to_str({ "Hello", "world" })
			eq("Hello\nworld", str)
		end)
		it("includes leading and trailing newlines", function()
			local str = utils.lines_to_str({ "", "Hello", "world", "" })
			eq("\nHello\nworld\n", str)
		end)
		it("includes empty lines", function()
			local str = utils.lines_to_str({ "Hello", "", "world" })
			eq("Hello\n\nworld", str)
		end)
		it("includes consecutive empty lines", function()
			local str = utils.lines_to_str({ "Hello", "", "", "", "", "world" })
			eq("Hello\n\n\n\n\nworld", str)
		end)
		it("is the inverse of str_to_lines", function()
			local str = "Hello\n\n\n\nWorld\n\rWith" .. string.char(27) .. "escapes"
			eq(str, utils.lines_to_str(utils.str_to_lines(str)))
		end)
	end)

	pending("remove_matching_suffix", function()
		-- utils.remove_matching_suffix(str, suffix)
	end)

	pending("remove_matching_prefix", function()
		-- utils.remove_matching_prefix(str, prefix)
	end)

	pending("subset", function()
		-- utils.subset(tbl, from, to)
	end)

	pending("script_path", function()
		-- utils.script_path()
	end)

	pending("prequire", function()
		-- utils.prequire("")
	end)

	pending("pumvisible", function()
		-- utils.pumvisible()
	end)

	pending("current_position", function()
		-- utils.current_position()
	end)

	--compatability with vim.endswith?
	describe("ends_with", function()
		it("works for values present", function()
			eq(true, utils.ends_with("123", "3"))
			eq(true, utils.ends_with("123", "123"))
		end)
		--- This is likely a bug! certainly counterintuitive
		it("returns false for empty suffixes", function()
			eq(false, utils.ends_with("123", ""))
			eq(false, utils.ends_with("long string here", ""))
			-- Note: this is true because the empty string, not the suffix
			eq(true, utils.ends_with("", ""))
		end)
		--- This is an odd exception present in the code. Should it be removed?
		it("always returns true for empty string", function()
			eq(true, utils.ends_with("", "123"))
			eq(true, utils.ends_with("", "Any random string"))
			eq(true, utils.ends_with("", ""))
		end)

		it("works for values not present", function()
			eq(false, utils.ends_with("123", " "))
			eq(false, utils.ends_with("123", "2"))
			eq(false, utils.ends_with("123", "1234"))
		end)

		it("errors on bad values", function()
			assert.error(wrap(utils.ends_with, "123", nil))
			assert.error(wrap(utils.ends_with, nil, "123"))
			assert.error(wrap(utils.ends_with, {}, "123"))
			--- no error on table. Is this intended behaivor?
			assert.not_error(wrap(utils.ends_with, "123", {}))
			assert.error(wrap(utils.ends_with, "123", false))
			assert.error(wrap(utils.ends_with, false, "123"))
		end)
	end)

	--compatability with vim.startswith?
	describe("starts_with", function()
		it("works for values present", function()
			eq(true, utils.starts_with("123", "1"))
			eq(true, utils.starts_with("123", "123"))
		end)
		it("returns true for empty prefixes", function()
			eq(true, utils.starts_with("123", ""))
			eq(true, utils.starts_with("", ""))
			eq(true, utils.starts_with("long string here", ""))
		end)
		--- This is an odd exception present in the code. Should it be removed?
		it("always returns true for empty string", function()
			eq(true, utils.starts_with("", "123"))
			eq(true, utils.starts_with("", "Any random string"))
			eq(true, utils.starts_with("", ""))
		end)

		it("works for values not present", function()
			eq(false, utils.starts_with("123", " "))
			eq(false, utils.starts_with("123", "2"))
			eq(false, utils.starts_with("123", "1234"))
		end)

		it("errors on bad values", function()
			assert.error(wrap(utils.starts_with, "123", nil))
			assert.error(wrap(utils.starts_with, nil, "123"))
			assert.error(wrap(utils.starts_with, {}, "123"))
			--- no error on table. Is this intended behaivor?
			assert.not_error(wrap(utils.starts_with, "123", {}))
			assert.error(wrap(utils.starts_with, "123", false))
			assert.error(wrap(utils.starts_with, false, "123"))
		end)
	end)

	pending("is_end_of_line", function()
		-- utils.is_end_of_line()
	end)

	pending("end_of_line", function()
		-- utils.end_of_line()
	end)

	pending("document_changed", function()
		-- utils.document_changed()
	end)

	pending("selected_text", function()
		-- utils.selected_text()
	end)

	pending("set", function()
		-- utils.set(array)
	end)

	pending("select_range", function()
		-- utils.select_range(range)
	end)

	pending("select_range", function()
		-- utils.select_range(range)
	end)
end)

local assert = require("luassert")
local spy = require("luassert.spy")
local utils = require("tabnine.utils")
local eq = assert.same
local Path = require("plenary.path")
table.pack, table.unpack = table.pack or vim.F.pack_len, table.unpack or unpack
--- Creates a wrapper that calls f with given args
--- use like: assert.error(wrap(f, 1, 3, 4), "error: here")
local function wrap(f, ...)
	local args = table.pack(...)
	return function()
		return f(table.unpack(args, 1, args.n))
	end
end
local function path_exists(path)
	return vim.uv.fs_stat(path) ~= nil
end

describe("utils", function()
	describe("debounce", function()
		it("works after waiting", function()
			local timeout, tests = 20, { 1, 2, 10 } -- note: increasing either of these will result in tests that take longer
			local s = spy.new(function() end)
			local f = utils.debounce(s, timeout)
			for _, call_count in ipairs(tests) do
				s:clear()
				for _ = 1, call_count do
					for _ = 1, 5 do -- call 5 times for every expected spy call
						f()
					end
					vim.wait(timeout + 10) -- wait until timeout expires (ensure it's called at least once)
				end
				assert.spy(s).called(call_count)
			end
		end)
		--TODO: Should debounce validate input on the initial call?
		---- Should negative values error (prob) -- the neovim source casts them to an unsigned long (a **really** big number)
		-- it("errors on bad values", function() end)
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

	describe("remove_matching_suffix", function()
		it("works", function()
			eq("hello", utils.remove_matching_suffix("hello.txt", ".txt"))
			eq("hello.txt", utils.remove_matching_suffix("hello.txt", ""))
			eq("", utils.remove_matching_suffix("hello.txt", "hello.txt"))
			eq("h", utils.remove_matching_suffix("hello.txt", "ello.txt"))
		end)
		it("doesn't remove things it shouldn't", function()
			eq("hello.txt", utils.remove_matching_suffix("hello.txt", "hello"))
			eq("hello.txt", utils.remove_matching_suffix("hello.txt", "ello"))
			eq("hello.txt", utils.remove_matching_suffix("hello.txt", "he"))
			eq("hello.txt", utils.remove_matching_suffix("hello.txt", "."))
		end)
		it("errors on bad values", function()
			assert.error(wrap(utils.remove_matching_suffix, "123", nil))
			assert.error(wrap(utils.remove_matching_suffix, nil, "123"))
			assert.error(wrap(utils.remove_matching_suffix, {}, "123"))
			--- no error on table. Is this intended behaivor?
			assert.not_error(wrap(utils.remove_matching_suffix, "123", {}))
			assert.error(wrap(utils.remove_matching_suffix, "123", false))
			assert.error(wrap(utils.remove_matching_suffix, false, "123"))
		end)
	end)

	---TODO: These are completely broken!
	describe("remove_matching_prefix", function()
		it("works", function()
			eq("o.txt", utils.remove_matching_prefix("hello.txt", "hello"))
			eq("hello.txt", utils.remove_matching_prefix("hello.txt", ""))
			eq("t", utils.remove_matching_prefix("hello.txt", "hello.txt"))
			eq("xt", utils.remove_matching_prefix("hello.txt", "hello.tx"))
		end)
		it("doesn't remove things it shouldn't", function()
			eq("hello.txt", utils.remove_matching_prefix("hello.txt", ".txt"))
			eq("hello.txt", utils.remove_matching_prefix("hello.txt", "ello"))
			eq("hello.txt", utils.remove_matching_prefix("hello.txt", ".t"))
			eq("hello.txt", utils.remove_matching_prefix("hello.txt", "."))
		end)
		it("errors on bad values", function()
			assert.error(wrap(utils.remove_matching_prefix, "123", nil))
			assert.error(wrap(utils.remove_matching_prefix, nil, "123"))
			assert.error(wrap(utils.remove_matching_prefix, {}, "123"))
			--- no error on table. Is this intended behaivor?
			assert.not_error(wrap(utils.remove_matching_prefix, "123", {}))
			assert.error(wrap(utils.remove_matching_prefix, "123", false))
			assert.error(wrap(utils.remove_matching_prefix, false, "123"))
		end)
	end)

	describe("subset", function()
		local tbl
		before_each(function()
			tbl = { 1, 2, 3, 4, nil, 5, 6, 7 }
		end)
		it("creates an array of the right length", function()
			eq({ 1, 2 }, utils.subset(tbl, 1, 2))
			eq({ 1, 2, 3 }, utils.subset(tbl, 1, 3))
			eq({}, utils.subset(tbl, 0, 0))
		end)
		it("creates a new array", function()
			assert.not_equal(tbl, utils.subset(tbl, 1, 3))
			assert.not_equal(tbl, utils.subset(tbl, 1, 99))
			assert.not_equal(tbl, utils.subset(tbl, 1, #tbl))
		end)
	end)

	describe("script_path", function()
		---@type string
		local this_path, root_path
		before_each(function()
			this_path = debug.getinfo(1, "S").source:sub(2):match("(.*)/") or "." -- the current file using debug.getinfo
			root_path = Path:new(this_path):find_upwards("lua/") -- Find the /lua/ folder
			if root_path == "" then root_path = nil end -- find_upwards returns an empty string on fail :(
			root_path = root_path and root_path:parent():absolute() -- get the parent directory as a string
		end)

		it("doesn't end in trailing slash", function()
			assert.not_matches(utils.script_path(), "/$")
		end)

		--- TODO: fix utils.script_path. It currently hardcodes to ../.. from the *calling* script
		--- In this case, this is the containing directory
		it("properly identitfies the root", function()
			eq(true, path_exists(utils.script_path()))
			--- TODO: These should return true
			eq(false, path_exists(utils.script_path() .. "/README.md"))
			eq(false, path_exists(utils.script_path() .. "/lua/"))
			--- TODO: this shouldn't need the dirname
			eq(vim.fs.dirname(root_path), vim.uv.fs_realpath(utils.script_path()))
		end)
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

	describe("set", function()
		it("doesn't handle nils", function() -- Should it?
			eq({ 1, 2, 3, 4 }, utils.set({ 1, 2, 3, 4, nil, 5, 6, 7 }))
			eq({ 1, 2, 4 }, utils.set({ 1, 2, 4, nil, 5, 3, 7 }))
			eq({ 1, 2, 3, 4 }, utils.set({ 1, 2, 3, 4, nil, 5, 6, n = 7 })) -- ignores the n key
		end)

		it("creates an array of the right length", function()
			eq({ 1, 2, 3, 4 }, utils.set({ 1, 2, 3, 4, 2, 3, 1 }))
			eq({ 1, 2, 3, 4 }, utils.set({ 1, 2, 3, 4 }))
			eq({}, utils.set({}))
		end)
		it("creates a new array", function()
			local tbl = { 1, 2, 3, 4 }
			assert.not_equal(tbl, utils.set(tbl))
			assert.not_equal({}, utils.set({}))
			assert.not_equal(utils.set(tbl), utils.set(tbl))
		end)
	end)

	pending("select_range", function()
		-- utils.select_range(range)
	end)
end)

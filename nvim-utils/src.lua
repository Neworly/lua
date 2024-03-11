local SOURCE = ":source"

local FILE_NAME = "main"
local GCC_FLAGS = "-Wall -Werror -o -lm"
local GCC_COMPILE = ":!gcc"

local CARGO_COMPILE = ":!cargo run"
local CARGO_DEBUG = ":!cargo debug"

local ASSEMBLER_FLAGS = "-O0 -fverbose-asm"

local KEYMAP_COMPILER = "cr"
local KEYMAP_DEBUG = "cd"

local function sformat(...)
		return (""):rep(#{ ... }+1, "%s "):format(...)
end

local function NOT_SUPPORTED_LANG(ft)
		return sformat(ft, "is not a supported language")
end

local function INVALID_DEBUG_OPTION(ft)
		return sformat(ft, "encountered an invalid debug option by 'this executive'")
end

local EXIT_SUCCESS, EXIT_FAILED = true, false
local OKEY, FAILED = true, false

local function catch(fn)
		local status, _ = pcall(fn)
		if not status then
				return EXIT_FAILED
		end
		return EXIT_SUCCESS
end

local function lang_opts()
		return {
				c = sformat(GCC_COMPILE, GCC_FLAGS, FILE_NAME..".c", FILE_NAME..".o"),
				casm = sformat(GCC_COMPILE, ASSEMBLER_FLAGS, FILE_NAME..".c"),
				lua = SOURCE,
				rust = {
						run = CARGO_COMPILE,
						debug = CARGO_DEBUG
				}
		}
end

local function active_file_ex()
		local path = vim.fn.expand("%")
		local path_len = path:len()
		local TERMINATOR = ("."):byte(1, 1)
		local buffer = ""

		for cursor = path_len, 1, -1 do
				local byte = path:byte(cursor);
				if byte == TERMINATOR then
						if buffer:len() == 0 then
							goto continue
						end
						buffer = buffer:reverse()
						return buffer
				end
		::continue::
				buffer = buffer .. string.char(byte)
		end

		return EXIT_FAILED
end

local function main()
		local opts = lang_opts()
		local file_type = active_file_ex();
		if not file_type then
			return EXIT_FAILED
		end

		local directive = opts[file_type]
		if not directive then
				print(NOT_SUPPORTED_LANG(file_type))
				return EXIT_FAILED
		end

		local function supported_run()
				if type(directive) == type({}) then
			            print("is", directive == "table")
			            if directive.run then
			                return OKEY
			            end
				    print(INVALID_DEBUG_OPTION(file_type))
          		            return FAILED
				end
				return OKEY
		end

		local function supported_debug()
				if type(directive) == "table" then
						print(INVALID_DEBUG_OPTION(file_type))
						return FAILED
				end
				return OKEY
		end

		local function compile()
				local status = supported_run()
				if not status then
					return
				end
        
				if type(directive) == "table" then
					vim.api.nvim_command(directive.run)
					return
				end
				vim.api.nvim_command(directive)
        --[[ weird, I'll work on that later >:D ]]
        if file_type == "c" then
            vim.api.nvim_command(string.format("!/%s", FILE_NAME))
        end
		end

		local function debug()
				local status = supported_debug()
				if not status then
					return
				end

				vim.api.nvim_command(directive.debug)
		end

		vim.keymap.set('n', KEYMAP_COMPILER, compile)
		vim.keymap.set('n', KEYMAP_DEBUG, debug)
end

vim.keymap.set('n', "sc", main)

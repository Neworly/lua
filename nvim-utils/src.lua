
local SOURCE = ":source"

local FILE_NAME = "main"
local EFILE_NAME = "lowmain"

local GCC_FLAGS = "-Wall -o"
local GCC_COMPILE = ":!gcc"

local CARGO_COMPILE = ":!cargo run"
local CARGO_DEBUG = ":!cargo debug"

local CASSEMBLER_FLAGS = "-S -fverbose-asm"

local ASM_COMPILER = ":!as"
local ASM_FLAGS = "-o"
local ASM_LINKER = "ld"

local KEYMAP_COMPILER = "cr"
local KEYMAP_DEBUG = "cd"
local KEYMAP_ASSEMBLE = "ca"

local function sformat(...)
		return (""):rep(#{ ... }+1, "%s "):format(...)
end

local function NOT_SUPPORTED_LANG(ft)
		return sformat(ft, "is not a supported language")
end

local function INVALID_DEBUG_OPTION(ft)
		return sformat(ft, "encountered an invalid debug option by 'this executive'")
end

local function INVALID_ASM_OPTION(ft)
		return sformat(ft, "an asssembler were not supported")
end


local EXIT_SUCCESS, EXIT_FAILED = 1, 0
local OKEY, FAILED = true, false

local function lang_opts()
		return {
				c = {
            run = sformat(GCC_COMPILE, GCC_FLAGS, FILE_NAME, FILE_NAME..".c"),
            asm = sformat(GCC_COMPILE, CASSEMBLER_FLAGS, FILE_NAME..".c"),
            linked = FILE_NAME
        }, s = {
            run = sformat(sformat(ASM_COMPILER, ASM_FLAGS, FILE_NAME..".o", FILE_NAME..".s"), ";", ASM_LINKER, ASM_FLAGS, EFILE_NAME, FILE_NAME..".o"),
            linked = EFILE_NAME
        },
				lua = SOURCE,
				cust = {
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

local function comp_mode(flag)
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
            if directive.run then
                return OKEY
            end
						print(INVALID_DEBUG_OPTION(file_type))
          	return FAILED
				end
				return OKEY
		end

		local function supported_debug()
				if type(directive) == "table" and not directive.run then
						print(INVALID_DEBUG_OPTION(file_type))
						return FAILED
				end
				return OKEY
		end


		local function supported_assemble()
				if type(directive) == "table" and not directive.asm then
						print(INVALID_ASM_OPTION(file_type))
						return FAILED
				end
				return OKEY
		end


		local function compile()
				local status = supported_run()
				if not status then
					  return
				end

        local function call_exe(com)
				    vim.api.nvim_command(com)
            if type(directive) == "table" and directive.linked then
                vim.api.nvim_command(string.format("!./%s", directive.linked))
            end
        end

				if type(directive) == "table" then
            call_exe(directive.run)
					  return
				end
        call_exe(directive)
		end

		local function debug()
				local status = supported_debug()
				if not status then
					return
				end

				vim.api.nvim_command(directive.debug)
		end

	  local function assemble()
				local status = supported_assemble()
				if not status then
					return
				end
				vim.api.nvim_command(directive.asm)
		end

    if flag == "debug" then
        debug()
        return
    end

    if flag == "assemble" then
        assemble()
        return
    end
    compile()
end

local function run()
    comp_mode("run")
end

local function recompile()
    comp_mode("debug")
end

local function asm()
    comp_mode("assemble")
end

vim.keymap.set('n', KEYMAP_COMPILER, run)
vim.keymap.set('n', KEYMAP_DEBUG, recompile)
vim.keymap.set('n', KEYMAP_ASSEMBLE, asm)

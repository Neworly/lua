local settings = {
  lang = {
    c = {
      GCC = {
        options = '-Wall -pedantic-errors -fsanitize=address -o',
        alias = 'gcc',
      },
    },

    lua = {
      comp = 'source',
    },
  },
  format = {
    EXCLUDED = -1,
  },
}

local KEYMAP_COMPILER = 'cr'

function get_file_format(filename)
  local file_format = filename:reverse()

  local s, e =
    0, (function()
      local ebyte = string.byte '.'
      for i = 1, file_format:len(), 1 do
        if file_format:byte(i) == ebyte then
          return i > 1 and i - 1 or i
        end
      end
      return -1
    end)()

  if settings.format.EXCLUDED == e then
    error(file_format:reverse() .. ' !! has no format')
    return settings.format.EXCLUDED
  end

  file_format = file_format:sub(s, e):reverse()
  return 0, file_format
end

function auth_format(filename)
  local retval, format = get_file_format(filename)

  if settings.format.EXCLUDED == retval then
    return false
  end

  local t = settings.lang[format]
  if not t then
    return false
  end

  return true, t
end

function compacker()
  local owner = io.open('pack.md', 'r')
  if not owner then
    return false
  end

  local lines = {}

  for line in owner:lines '*l' do
    line = line:gsub(' ', '')
    if line:len() == 0 then
    else
      if auth_format(line) then
        table.insert(lines, line)
      end
    end
  end

  if #lines == 0 then
    return false
  end

  return true, lines
end

function compile(filename, lang)
  if type(lang) ~= 'table' then
    return
  end

  if lang.source then
    vim.api.nvim_command(string.format('!source %s', filename))
  elseif lang.GCC then
    local bin = {}

    local commexe, commrun
    do
      local alias, opt = lang.GCC.alias, lang.GCC.options
      local prefix = '!' .. alias .. ' '
      local this = filename:gsub('.c', '')
      table.insert(bin, this)
      local suffix = string.format(' %s %s', this, filename)
      commexe = prefix .. opt .. suffix
      commrun = '!./' .. this
    end
    vim.api.nvim_command(commexe)
    vim.api.nvim_command(commrun)
  end

  return true
end

function file_in_focus()
  local filename = vim.fn.expand '%'
  local retval, t = auth_format(filename)
  if not retval then
    return
  end
  compile(filename, t)
end

function run()
  local retval, pack = compacker()
  if not retval then
    file_in_focus()
    return
  end

  local files = {}
  for _, v in pairs(pack) do
    local _, t = auth_format(v)
    if not _ then
      return
    end

    if compile(v, t) then
      table.insert(files, v)
    end
  end

  collectgarbage 'collect'
end

vim.keymap.set('n', KEYMAP_COMPILER, run)

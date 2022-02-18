--
-- A lot of ideas and principles are taken from LuaJIT's
-- source code, which is released under the following license:
-- https://github.com/LuaJIT/LuaJIT/blob/master/COPYRIGHT
--
-- Lexer. Convert input into a stream of tokens.
--

class 'LuaLexer'

local char = include 'char.lua'
local LUA_TOKENS = {
  ['and']       = 'and',          ['in']        = 'in',             ['..']        = 'concat',
  ['break']     = 'break',        ['local']     = 'local',          ['...']       = 'dots',
  ['do']        = 'do',           ['nil']       = 'nil',            ['==']        = 'eq',
  ['else']      = 'else',         ['not']       = 'not',            ['>=']        = 'ge',
  ['elseif']    = 'elseif',       ['or']        = 'or',             ['<=']        = 'le',
  ['end']       = 'end',          ['return']    = 'return',         ['!=']        = 'ne',
  ['false']     = 'false',        ['then']      = 'then',           ['~=']        = 'lne',
  ['for']       = 'for',          ['true']      = 'true',           ['<number>']  = 'number',
  ['function']  = 'function',     ['while']     = 'while',          ['<name>']    = 'name',
  ['if']        = 'if',           ['continue']  = 'continue',       ['<string>']  = 'string',
                                                                    ['<eof>']     = 'eof',
                                                                    ['<comment>'] = 'comment'
}
local TK_TO_REPRESENTATION = {}
local NAME_TO_ENUM = {}
local TK_TO_VISUAL = {}
local idx = 256

-- Generate enums
for k, v in pairs(LUA_TOKENS) do
  _G['TK_'..v] = idx
  TK_TO_REPRESENTATION[idx] = k
  NAME_TO_ENUM[k] = idx
  TK_TO_VISUAL[idx] = v
  idx = idx + 1
end

TK_add        = string.byte '+'
TK_assign     = string.byte '='
TK_band       = string.byte '&'
TK_bflip      = string.byte '~'
TK_bor        = string.byte '|'
TK_colon      = string.byte ':'
TK_comma      = string.byte ','
TK_div        = string.byte '/'
TK_dot        = string.byte '.'
TK_ex         = string.byte '!'
TK_gt         = string.byte '>'
TK_lbrace     = string.byte '{'
TK_lbracket   = string.byte '['
TK_length     = string.byte '#'
TK_lparen     = string.byte '('
TK_lt         = string.byte '<'
TK_mod        = string.byte '%'
TK_mul        = string.byte '*'
TK_question   = string.byte '?'
TK_rbrace     = string.byte '}'
TK_rbracket   = string.byte ']'
TK_rparen     = string.byte ')'
TK_semicolon  = string.byte ';'
TK_sub        = string.byte '-'
TK_tild       = string.byte '~'
TK_vbar       = string.byte '|'
TK_xor        = string.byte '^'
TK_space      = string.byte ' '
TK_tab        = string.byte '\t'
TK_cr         = string.byte '\r'
TK_lf         = string.byte '\n'

function LuaLexer:visualize(tk)
  if tk > 255 then
    return 'TK_'..TK_TO_VISUAL[tk]
  else
    return string.char(tk)
  end
end

function LuaLexer:tokenize(input, extended)
  local tokens = {}
  local buf = ''
  local cur_pos = 1
  local line = 1

  if !input then return false end

  local function peek()
    local char = input[cur_pos + 1]
    return char, string.byte(char)
  end

  local function next()
    local char = input[cur_pos + 1]
    cur_pos = cur_pos + 1
    return char, string.byte(char)
  end

  local function this()
    local char = input[cur_pos]
    return char, string.byte(char)
  end

  local function save()
    local char = input[cur_pos]
    buf = buf..char
    return char
  end

  local function save_next()
    save() return next()
  end

  local function save_manual(char)
    buf = buf..char
    return char, string.byte(char)
  end

  local function clear()
    local old_buf = buf
    buf = ''
    return old_buf
  end

  local function push(tk, val)
    table.insert(tokens, { tk = tk, val = val, line = line, pos = cur_pos })
  end

  local function lex_number(current, char_id)
    -- hex number
    if peek() == 'x' then
      save_next()

      while char.is_hex(char_id) do
        current, char_id = save_next()
      end

      push(TK_number, clear())
      return
    end

    while char.is_num(char_id) do
      current, char_id = save_next()
    end

    push(TK_number, clear())
  end

  local function read_long_string(current, char_id)
    local newlines = 0
    local buf = ''
    while true do
      current, char_id = next()
      if current == ']' and peek() == ']' then
        next() next() -- eat ] and then jump to the next fresh thing
        return buf, newlines
      elseif !current or !char_id then
        return buf, newlines
      end

      if current == '\n' then newlines = newlines + 1 end

      buf = buf..current
    end
  end

  local function read_string(current, char_id)
    local newlines = 0
    local opener = current

    current, char_id = next() -- eat opener

    while true do
      if current == opener then
        next() -- eat opener
        break
      end

      if current != '\\' then
        current, char_id = save_next()
      end

      if current == '\\' then
        current, char_id = next()

        if     current == 'a' then save_manual('\a')
        elseif current == 'b' then save_manual('\b')
        elseif current == 'f' then save_manual('\f')
        elseif current == 'n' then save_manual('\n')
        elseif current == 'r' then save_manual('\r')
        elseif current == 't' then save_manual('\t')
        elseif current == 'v' then save_manual('\v')
        elseif current == '\n' or current == '\r' then
          save_manual('\n')
          newlines = newlines + 1
        elseif current == '\'' or current == '"' or current == '\\' then
          save_manual(current)
        end

        current, char_id = next()
      elseif current == '\n' then
        newlines = newlines + 1
      elseif !current or !char_id then
        break
      end
    end
    return clear(), newlines
  end

  -- Same basic principle as LuaJIT's lexer.
  local function lex()
    local current, char_id = this()

    if char.is_ident(char_id) and current != '!' and current != '?' then
      if char.is_num(char_id) then
        lex_number(current, char_id)
        return true
      end

      while char.is_ident(char_id) do
        current, char_id = save_next()
      end

      if LUA_TOKENS[buf] then
        push(NAME_TO_ENUM[buf], clear())
        return true
      end

      push(TK_name, clear())
      return true
    end

    if current == '\n' then
      line = line + 1
      next()
      if extended then push(TK_lf, '\n') end
      return true
    elseif current == ' ' or current == '\t'
      or current == '\v' or current == '\f'
      or current == ';' then
        if extended and (current != '\v' and current != '\f') then
          push(string.byte(current), current)
        end
        next()
        return true
    elseif current == '-' then
      current, char_id = next()
      -- comment
      if current == '-' then
        current, char_id = next()

        if current == '[' and next() == '[' then -- long comment
          current, char_id = next() -- eat [
          local buf, newlines = read_long_string(current, char_id)
          line = line + newlines
          push(TK_comment, buf)
          clear()
        else -- short comment
          while current != '\n' do
            current, char_id = save_next()
          end
          push(TK_comment, clear())
        end
        return true
      end

      push(TK_sub, '-')
      return true
    elseif current == '+' then
      current, char_id = next()
      push(TK_add, '+')
      return true
    elseif current == '*' then
      current, char_id = next()
      push(TK_mul, '*')
      return true
    elseif current == '/' then
      current, char_id = next()
      if current == '/' then -- C-style comment (thanks garry)
        next() -- eat /
        while current != '\n' do
          current, char_id = save_next()
        end
        push(TK_comment, clear())
        return true
      elseif current == '*' then -- C-style long comment
        next() -- eat *
        while true do
          current, char_id = save_next()

          if current == '*' and peek() == '/' then
            next() -- eat *
            next() -- eat /
            break
          end
        end
        push(TK_comment, clear())
        return true
      end

      push(TK_div, '/')
      return true
    elseif current == '|' then
      current, char_id = next()

      if current == '|' then
        current, char_id = next()
        push(TK_or, '||')
        return true
      end

      push(TK_vbar, '|')
      return true
    elseif current == '&' then
      current, char_id = next()

      if current == '&' then
        current, char_id = next()
        push(TK_and, '&&')
        return true
      end

      push(string.byte('&'), '&')
      return true
    elseif current == '>' then
      current, char_id = next()
      if current != '=' then push(TK_gt, '>')
      else next() push(TK_ge, '>=') end
      return true
    elseif current == '<' then
      current, char_id = next()
      if current != '=' then push(TK_lt, '<')
      else next() push(TK_le, '<=') end
      return true
    elseif current == '!' then
      current, char_id = next()
      if current != '=' then push(TK_ex, '!')
      else next() push(TK_ne, '!=') end
      return true
    elseif current == '~' then
      current, char_id = next()
      if current != '=' then push(TK_tild, '~')
      else next() push(TK_ne, '~=') end
      return true
    elseif current == '=' then
      current, char_id = next()
      if current != '=' then push(TK_assign, '=')
      else next() push(TK_eq, '==') end
      return true
    elseif current == '\'' or current == '"' then
      push(TK_string, read_string(current, char_id))
      return true
    elseif current == '[' and peek() == '[' then
      next() -- eat [
      next() -- eat another [
      push(TK_string, read_long_string())
      return true
    elseif current == '.' then
      current, char_id = next()

      if current == '.' then
        current, char_id = next()

        if current == '.' then
          push(TK_dots, '...')
          next()
          return true
        end

        push(TK_concat, '..')
        return true
      end

      push(TK_dot, '.')
      return true
    elseif current and char_id then -- single-char tokens
      push(char_id, current)
      current, char_id = next()
      clear()
      return true
    end

    return false
  end

  while lex() do
    -- just loop will ya...
  end

  return tokens
end

local M = {}

-- NOTES
-- how do we know after a command when we should reingage our editable-multiline
-- after a command we need to find a new prompt
--
-- where do we find the prompt
-- either in termleave, or termenter
--
--
-- maybe try an approach like this:
-- on each command we lose the prompt location
-- we dont editable do anything if we dont know the location
--
-- we reenable our editable as soon as we find another prompt location
-- this could be on textchangedT, textchanged, termleave whatever












-- keep track if we support multiline editing or not via command used.
-- enabled in CR keybind for T mode and disabled on termenter again
-- disabled also on termleave if we found a prompt to make sure to be insta editable again.
-- this enables us to know on textchanged if this is false we are multilinin
-- if we come into textchanged with true we actually make the line blank since we know this
-- will be the state once we get out of execution
-- questions:
-- will textchanged be triggered on leaving term and when before we make sure its false again or?

local function get_multiline(buf)
  local lines = vim.api.nvim_buf_get_lines(0, buf.prompt.row - 1, buf.prompt.row + 3, false)
  local line = ""

  vim.notify("multiline moment with line: " .. line)
  for k, v in ipairs(lines) do
    if (k == 1) then
      line = lines[1]:sub(buf.prompt.col + 1)
    else
      line = line .. v
    end
  end

  return line
end

-- saves the line for later rewrite in termenter
local function save_line(buf)
  if (buf.command_used) then
    vim.notify("command moment")
    return
  end

  buf.prompt.line = get_multiline(buf)
end

local function replace_term_codes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function clear_line(buf)
  return vim.api.nvim_chan_send(vim.bo.channel,
    replace_term_codes(buf.keybinds.clear_line))
end

local function insert_line(buf)
  return vim.api.nvim_chan_send(vim.bo.channel, buf.prompt.line)
end

-- necessary for 'a' keybind or 'A' and stuff
local function set_term_cursor(cursor_col)
  local buf = M.buffers[vim.api.nvim_get_current_buf()]
  local p = replace_term_codes(buf.keybinds.goto_startof_line) ..
      vim.fn['repeat'](replace_term_codes(buf.keybinds.move_char_forward),
        cursor_col - buf.prompt.col)
  vim.api.nvim_chan_send(vim.bo.channel, p)
end

-- todo: can we do this without flickering? at all?
-- like maybe in one function call will be faster and better? but i dont think that matters at all but atleast try it out man
local function update_line(buf)
  local err_clear = clear_line(buf)
  local err_insert = insert_line(buf)

  -- maybe make sure that we actually reset terinal cursor to be where we want it to be?
  if (err_clear or err_insert) then
    return error("Wasn't able to update line in terminal")
  end
end

local function setup_keybinds(buffer)
  vim.keymap.set('t', '<CR>', function()
    local buf = M.buffers[buffer]
    local cursor = vim.api.nvim_win_get_cursor(0)
    buf.prompt.line = ""
    buf.prompt.row = cursor[1]
    buf.command_used = true
    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  end, { expr = true, buffer = buffer })

  vim.keymap.set('n', 'i', function()
    local buf = M.buffers[buffer]
    local cursor = vim.api.nvim_win_get_cursor(0)
    buf.prompt.cursor_col = cursor[2]
    vim.cmd("startinsert")
  end, { buffer = buffer })

  -- vim.keymap.set('n', 'i', function()
  -- end, { pattern = M.buf_pattern})

  -- vim.keymap.set('n', 'I', function()
  -- end, { pattern = M.buf_pattern})
  --
  -- vim.keymap.set('n', 'i', function()
  -- end, { pattern = M.buf_pattern})

  vim.keymap.set('n', 'a', function()
    local buf = M.buffers[buffer]
    local cursor = vim.api.nvim_win_get_cursor(0)
    buf.prompt.cursor_col = cursor[2] + 1
    vim.cmd("startinsert")
  end, { buffer = buffer })

  -- vim.keymap.set('n', 'dd', function()
  -- end, { pattern = M.buf_pattern })
end

local function setup_cmds()
  local group = vim.api.nvim_create_augroup("termbuf-edit", {});

  vim.api.nvim_create_autocmd('TextYankPost', {
    pattern = M.buf_pattern,
    group = group,
    callback = function(args)
      local start = vim.api.nvim_buf_get_mark(args.buf, '[')
      local ent = vim.api.nvim_buf_get_mark(args.buf, ']')
      local buf = M.buffers[args.buf]


      if start[1] ~= ent[1] then
      elseif vim.v.event.operator == 'c' then
        local line = vim.api.nvim_get_current_line()
        line = line:sub(1, start[2]) .. line:sub(ent[2] + 2)
        buf.prompt.line = line:sub(buf.prompt.col + 1)
        if start[1] == ent[1] and start[2] == ent[2] then
          buf.prompt.cursor_col = start[2] - 1
        else
          buf.prompt.cursor_col = start[2]
        end
      end
    end
  })

  vim.api.nvim_create_autocmd("TextChanged", {
    pattern = M.buf_pattern,
    group = group,
    callback = function(args)
      -- this callback also will be called if you change inside terminal mode
      -- and then go back out then the line will also be updated.
      local buf = M.buffers[args.buf]

      if (buf.prompt.col == nil) then
        return
      end

      save_line(buf)
    end
  })
  
  vim.api.nvim_create_autocmd("TextChangedT", {
    pattern = M.buf_pattern,
    group = group,
    callback = function(args)
      local buf = M.buffers[args.buf]

      -- if we didnt use command therefore we search for a fresh prompt location
      if not buf.command_used then
        local line = vim.api.nvim_get_current_line()
        print("current line in textchangedt")
      end
    end
  })

  -- so currently termenter actually happens before nvim does its weird magic by rewriting the deleted line in a terminal
  -- therefore even if we clear line and then rewrite it afterwards nvim adds their weird spaces back into the line..
  -- TODO: therefore there are spaces in the end of line. MAYBE, we dont need to care about it since the only time it
  -- this matter is on a, i , etc commands. If we then set_cursor manually again it might just work. without issues again
  vim.api.nvim_create_autocmd("TermEnter", {
    pattern = M.buf_pattern,
    group = group,
    callback = function(args)
      local buf = M.buffers[args.buf]

      if (buf.prompt.row == nil or buf.prompt.col == nil) then
        return
      end
      vim.notify("setting it false in termenter")
      buf.command_used = false
      update_line(buf)
      set_term_cursor(buf.prompt.cursor_col)
    end
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    pattern = M.buf_pattern,
    group = group,
    callback = function(args)
      local buf = M.buffers[args.buf]
      local cur = vim.api.nvim_win_get_cursor(0)
      if (buf.command_used) then
        vim.bo.modifiable = false
        return
      end

      if (buf.prompt.col ~= nil and buf.prompt.col ~= nil) then
        vim.bo.modifiable = (buf.prompt.row == cur[1] and buf.prompt.col <= cur[2]) or buf.prompt.row < cur[1]
      end
    end
  })

  -- this triggers before a textyankpost. This is crucial since if we try to use ci" on an empty string no text
  -- yank post will be triggered but this STILL will be triggered and we can catch the edge case here.
  -- todo: we can probably just modifiable false here in the right occasion when cursor_col == nil
  -- then we can do modifiable false and then feedkeys a/i to land at exact location
  -- vim.api.nvim_create_autocmd("ModeChanged", {
  --   group = group,
  --   callback = function(args)
  --     if vim.bo[args.buf].buftype == "terminal" then
  --       local buf = M.buffers[args.buf]
  --
  --       if buf.prompt.cursor_col == nil then
  --         -- Save old error writer
  --         local old_err_write = vim.api.nvim_err_write
  --         vim.api.nvim_err_write = function(_) end
  --
  --         -- Flip modifiable off (cancels ci" etc.)
  --         vim.bo.modifiable = false
  --         buf.prompt.cursor_col = vim.api.nvim_win_get_cursor(0)
  --
  --         -- Restore error handler in the next tick
  --         vim.schedule(function()
  --           vim.api.nvim_err_write = old_err_write
  --
  --           vim.api.nvim_feedkeys(
  --             vim.api.nvim_replace_termcodes("i", true, false, true),
  --             "n", -- non-remappable
  --             false -- don't wait for input
  --           )
  --         end)
  --       end
  --     end
  --   end
  -- })

  -- todo: modifiable false if prompt.cursor_col is null that itt will jump to the point it needs to go and then start insert manually after!
  -- this way only ci" where prompt.cursor_col cant be set will get into this state. this kind of sucks but it is the
  -- only way i see to trick the system

  vim.api.nvim_create_autocmd("TermLeave", {
    pattern = M.buf_pattern,
    group = group,
    callback = function(args)
      local buf = M.buffers[args.buf]
      local cursor = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_win_set_cursor(0, cursor);
      local line = vim.api.nvim_get_current_line()
      vim.notify("termleave current line btw: " .. line)

      local found = false
      for prompt, _ in pairs(M.prompts) do
        local s, e = line:find(prompt)
        if (s ~= nil) then
          buf.prompt = {
            line = line:sub(e + 1),
            row = cursor[1],
            col = e
          }

          buf.command_used = false
        end
      end
    end
  })
end

--- Set up the plugin internally on termopen
---@return nil
local function setup()
  setup_cmds()

  local augr_term = vim.api.nvim_create_augroup("termbuf", {})
  vim.api.nvim_create_autocmd('TermOpen', {
    pattern = M.buf_pattern,
    group = augr_term,
    callback = function(args)
      -- setup default values
      M.buffers[args.buf] = {
        command_used = false,
        keybinds = M.default_keybinds,
        prompt = {
          line = nil,
          row = nil,
          col = nil,
          -- this represents where we want the term cursor to be after entering the terminal mode again
          -- we cannot do this inside 'a' keybinds directly since this will be overwriten by update_line call in termenter
          -- autocommand. we simply set it inside 'a' or 'i' keybinds and make sure we move it there once we go into term enter
          cursor_col = nil
        },
      }
      setup_keybinds(args.buf)
    end
  })
end

---@class Keybinds
---@field clear_line string Key to clear the current line in editable regions
---@field move_char_forward string Key to move forward one character
---@field goto_startof_line string Key to move to the start of the line

---@class PromptOptions
---@field keybinds? Keybinds Custom keybindings for this specific prompt pattern

---@class TermBufConfig
---@field prompts? {[string]: PromptOptions} Table of prompt patterns mapping to their options. Keys are Lua pattern strings that match terminal prompts (e.g., '.*[$#%%][ ]?')
---@field default_keybinds? Keybinds Default keybindings for your terminal

--- Set up the termbuf plugin with the configuration
---@param config TermBufConfig Configuration table for editable-term
---@return nil
M.setup = function(config)
  -- this might not make sense since modifiable ruined on different command term outputs
  M.buf_pattern = "term://*"
  M.buffers = {};
  M.prompts = config.prompts or {
    -- space needs to be included!!!
    ['.*[$#%%][ ]'] = {},
    ["%(%gdb%)[ ]"] = {},
    ["^ghci>%s"] = {}
    -- todo
    -- not yet supported!
    -- if you want to add different keybinds for the a prompt
    -- ['# '] = {
    --   keybinds = {
    --     clear_current_line = '<C-e><C-u>',
    --     forward_char = '<C-f>',
    --     goto_line_start = '<C-a>',
    --   }
    -- }
  }

  M.default_keybinds = {
    clear_line = '<C-e><C-u>',
    move_char_forward = '<C-f>',
    goto_startof_line = '<C-a>',
  }
  setup()
end

return M

vim.keymap.set({ 'i', 'v', 's' }, '<C-c>', '<Esc>', { noremap = true })

-- vim remaps
vim.keymap.set('n', '<Leader>pv', vim.cmd.Ex)

-- moving lines in visual mode, nice
-- remaps for staying in the middle on ctrl d/u for halfway jumps
vim.keymap.set('n', '<C-d>', "<C-d>zz")
vim.keymap.set('n', '<C-u>', "<C-u>zz")

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- search terms stay in the middle
vim.keymap.set('n', 'n', "nzzzv")
vim.keymap.set('n', 'N', "Nzzzv")

-- copy logics
-- vim.keymap.set('n', 'd', "\"_d")
-- vim.keymap.set('x', 'p', "\"_dP")
-- dont copy on delete
-- vim.keymap.set('v', 'd', "\"_d")
-- vim.keymap.set('n', 'dd', "\"_dd")
-- dont copy on diw etc
-- vim.keymap.set('n', 'd', "\"_d")
-- dont copy on ciw etc
-- this breaks ciw from editable term btw lol
-- vim.keymap.set('n', 'c', "\"_c")

-- for system clipboard use leader copy
vim.keymap.set('x', '<leader>p', "\"_dP")
vim.keymap.set('n', '<leader>y', "\"+y")
vim.keymap.set('v', '<leader>y', "\"+y")

-- TODO: if i notice i will mess up ctrl-f on editing terms and do ctrl-c i will change it via
-- term open keymap specific for buffer in harpoon.lua and make sure it sends ctrl-c to term only
-- in the noirmal mode
-- go out of terminal mode easy access
vim.keymap.set('t', '<C-f>', '<C-\\><C-n>')

-- command line window remap magic. ctrl-f being a toggle now
vim.keymap.set({ 'i', 'v', 'n' }, '<C-f>', function()
  local keys = vim.api.nvim_replace_termcodes('<Esc><C-c>', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { noremap = true, silent = true })

-- command line window only tbh
-- vim.keymap.set('n', ':', function()
--   local buftype = vim.bo.buftype
--   if buftype == 'prompt' or buftype == 'nofile' then
--     return
--   end
--   vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(':<C-f>A', true, true, true), 'n', false)
-- end, {
--   noremap = true,                          -- Prevent recursive mapping of ':'
--   silent = true,                           -- Don't echo the simulated keys
--   desc = "Always open CmdWin+Insert for :" -- Description for :Telescope keymaps
-- })

-- Literal search and replace
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- showing up diagnostics with newlines in a floating window
vim.keymap.set({ "n" }, "<leader>cd", vim.diagnostic.open_float)


-- tabbing around projects like this is emacs fr
vim.keymap.set("n", "<leader>1", "<Cmd>tabn 1<CR>")

-- could map this via sending esc + ^[1 sequence in iterm keybinds
-- maybe one day lets see if i can work with only nvim tabs froim now on then i might
-- legit switch to only using nvim and also rebinding cmd+t/w and stuff
for i = 1, 9 do
  vim.keymap.set({ 'n', 'i', 'v', 't', 'c' }, '<M-' .. i .. '>', '<Cmd>tabn ' .. i .. '<CR>',
    { desc = 'Go to tab ' .. i })
end

vim.keymap.set({ 'n', 'i', 'v', 't', 'c' }, '<M-w>', '<Cmd>tabclose<CR>', { desc = 'Close tab' })
vim.keymap.set({ 'n', 'i', 'v', 't', 'c' }, '<M-t>', function()
  vim.cmd('tabnew')
  vim.cmd('tcd ~')
  vim.cmd('term')
  vim.cmd('startinsert')
end, { desc = 'open fresh term in home' })

vim.keymap.set("n", "<leader>2", "<Cmd>tabn 2<CR>")
vim.keymap.set("n", "<leader>3", "<Cmd>tabn 3<CR>")
vim.keymap.set("n", "<leader>4", "<Cmd>tabn 4<CR>")
vim.keymap.set("n", "<leader>w", "<Cmd>tabclose<CR>")
-- move tabs
vim.keymap.set("n", "<leader>H", function() vim.cmd("tabmove -1") end)
vim.keymap.set("n", "<leader>L", function() vim.cmd("tabmove +1") end)

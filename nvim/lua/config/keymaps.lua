-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Center cursor after moving down half-page" })
-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Center cursor after moving up half-page" })

vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { desc = "Rename" })

-- Window splits (matching tmux style: Ctrl+w \ and Ctrl+w -)
vim.keymap.set("n", "<C-w>\\", "<cmd>vsplit<cr>", { desc = "Vertical split" })
vim.keymap.set("n", "<C-w>-", "<cmd>split<cr>", { desc = "Horizontal split" })

-- Smart resize: moves the border in the direction of hjkl (like tmux)
local function smart_resize(dir, amount)
  if dir == "h" or dir == "l" then
    local cur = vim.fn.winnr()
    vim.cmd("wincmd l")
    local is_rightmost = vim.fn.winnr() == cur
    if not is_rightmost then vim.cmd("wincmd p") end

    -- h=border left, l=border right
    -- Rightmost: h=grow, l=shrink. Others: h=shrink, l=grow
    local grow = (is_rightmost and dir == "h") or (not is_rightmost and dir == "l")
    vim.cmd("vertical resize " .. (grow and "+" or "-") .. amount)
  else
    local cur = vim.fn.winnr()
    vim.cmd("wincmd j")
    local is_bottommost = vim.fn.winnr() == cur
    if not is_bottommost then vim.cmd("wincmd p") end

    -- j=border down, k=border up
    -- Bottommost: k=grow, j=shrink. Others: j=grow, k=shrink
    local grow = (is_bottommost and dir == "k") or (not is_bottommost and dir == "j")
    vim.cmd("resize " .. (grow and "+" or "-") .. amount)
  end
end

-- Window resizing with Ctrl+Shift+hjkl (requires alacritty keybindings)
-- Alacritty sends custom escape sequences: ESC _ R {H,J,K,L}
vim.keymap.set("n", "\x1b_RH", function() smart_resize("h", 5) end, { desc = "Resize left" })
vim.keymap.set("n", "\x1b_RL", function() smart_resize("l", 5) end, { desc = "Resize right" })
vim.keymap.set("n", "\x1b_RJ", function() smart_resize("j", 2) end, { desc = "Resize down" })
vim.keymap.set("n", "\x1b_RK", function() smart_resize("k", 2) end, { desc = "Resize up" })

-- NOTE: This interferes with LazyGit, so removing!
-- Thank you, https://www.reddit.com/r/neovim/comments/1do3zgm/help_with_lazygit_plugin/

-- -- Check if Neovim is running
-- if vim.fn.has("nvim") == 1 then
--   -- Auto command for terminal open to map <Esc> to exit terminal mode
--   vim.api.nvim_create_autocmd("TermOpen", {
--     pattern = "*",
--     callback = function()
--       vim.api.nvim_buf_set_keymap(0, "t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
--     end,
--   })
-- end

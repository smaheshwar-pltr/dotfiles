-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Center cursor after moving down half-page" })
-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Center cursor after moving up half-page" })

vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { desc = "Rename" })

-- Window splits (matching tmux style with Ctrl instead of prefix)
-- Ctrl+\ for vertical split, Ctrl+- for horizontal split
vim.keymap.set("n", "<C-\\>", "<cmd>vsplit<cr>", { desc = "Vertical split" })
vim.keymap.set("n", "<C-_>", "<cmd>split<cr>", { desc = "Horizontal split" }) -- Ctrl+- sends C-_

-- Window resizing with Ctrl+Shift+hjkl (requires alacritty keybindings)
-- These map to the escape sequences sent by alacritty
vim.keymap.set("n", "<C-S-h>", "<cmd>vertical resize -5<cr>", { desc = "Resize window left" })
vim.keymap.set("n", "<C-S-j>", "<cmd>resize -2<cr>", { desc = "Resize window down" })
vim.keymap.set("n", "<C-S-k>", "<cmd>resize +2<cr>", { desc = "Resize window up" })
vim.keymap.set("n", "<C-S-l>", "<cmd>vertical resize +5<cr>", { desc = "Resize window right" })

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

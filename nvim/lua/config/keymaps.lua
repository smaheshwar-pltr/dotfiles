-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Center cursor after moving down half-page" })
-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Center cursor after moving up half-page" })

vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { desc = "Rename" })

-- Check if Neovim is running
if vim.fn.has("nvim") == 1 then
  -- Auto command for terminal open to map <Esc> to exit terminal mode
  vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*",
    callback = function()
      vim.api.nvim_buf_set_keymap(0, "t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
    end,
  })
end

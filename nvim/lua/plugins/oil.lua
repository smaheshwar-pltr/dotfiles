return {
  "stevearc/oil.nvim",
  opts = {},
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory (Oil)" },
    { "<leader>o", "<cmd>Oil --float<cr>", desc = "Open Oil (float)" },
  },
}

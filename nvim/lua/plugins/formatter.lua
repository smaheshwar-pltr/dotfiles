return {
  -- https://github.com/LazyVim/LazyVim/discussions/3144
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cpp = { "clang-format" },
        c = { "clang-format" },
        h = { "clang-format" },
        hpp = { "clang-format" },
      },
      -- Lazyvim complains if this is kept.
      -- format_on_save = {
      --   timeout_ms = 500, -- TODO: What does this do?
      --   lsp_fallback = true, -- Don't think we need this.
      -- },
    },
  },
}

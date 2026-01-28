return {
  -- Catppuccin (Mocha)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false, -- IMPORTANT: must load before colorscheme is applied
    priority = 1000, -- ensure it loads first
    opts = {
      flavour = "mocha",
      transparent_background = true, -- makes nvim bg match terminal bg
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  },

  -- Gruvbox kept so you can toggle
  { "ellisonleao/gruvbox.nvim", lazy = true },

  -- LazyVim config
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
      -- colorscheme = "gruvbox",
    },
  },
}

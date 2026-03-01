return {
  -- Enable inline ghost text suggestions
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-k>",
          accept_line = "<M-j>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
    },
  },

  -- Disable copilot-cmp so it doesn't conflict
  {
    "zbirenbaum/copilot-cmp",
    enabled = false,
  },
}

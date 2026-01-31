return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  event = "BufReadPost",
  keys = {
    { "<leader>o", "<cmd>AerialToggle!<cr>", desc = "Toggle Outline (ToC / Symbols)" },
  },
  opts = {
    attach_mode = "global",
    backends = { "lsp", "treesitter", "markdown", "man" },
    show_guides = true,
    layout = {
      max_width = { 40, 0.25 },
      min_width = 30,
      default_direction = "prefer_right",
      placement = "edge",
    },
    -- VSCode Outlineに近いシンボル表示
    filter_kind = {
      _ = {
        "Class",
        "Constant",
        "Constructor",
        "Enum",
        -- "EnumMember",
        "Field",
        "Function",
        "Interface",
        "Method",
        "Module",
        "Namespace",
        "Package",
        -- "Property",
        "Struct",
        -- "TypeParameter",
      },
      markdown = { "Interface" },
    },
    -- 明示的に設定してnilエラーを防ぐ
    ignore = {
      unlisted_buffers = false,
      diff_windows = true,
      filetypes = {},
      buftypes = "special",
      wintypes = "special",
    },
    manage_folds = false,
    link_tree_to_folds = true,
    link_folds_to_tree = false,
    guides = {
      mid_item = "├─",
      last_item = "└─",
      nested_top = "│ ",
      whitespace = "  ",
    },
    -- シンボルに階層的な連番を付ける (1. func → 1.1 var)
    post_add_all_symbols = function(bufnr, items, ctx)
      local function number_nodes(nodes, prefix)
        prefix = prefix or ""
        for i, item in ipairs(nodes) do
          local num = prefix == "" and tostring(i) or (prefix .. "." .. i)
          item.name = string.format("%s. %s", num, item.name)
          if item.children and #item.children > 0 then
            number_nodes(item.children, num)
          end
        end
      end
      number_nodes(items)

      return items
    end,
  },
}

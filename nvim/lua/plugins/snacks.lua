return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  ---@type snacks.Config
  opts = {
    styles = {
      snacks_image = {
        keys = {
          q = "close",
          ["<Esc>"] = "close",
        },
      },
    },
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true,
        float = true,
        max_width = 120,
        max_height = 60,
      },
      convert = {
        notify = true,
        magick = {
          default = { "{src}[0]", "-scale", "3840x2160>" },
        },
        mermaid = function()
          local theme = vim.o.background == "light" and "neutral" or "dark"
          return {
            "-i", "{src}",
            "-o", "{file}",
            "-b", "transparent",
            "-t", theme,
            "-s", "3",
            "-w", "3200",  -- 幅を明示的に指定
            "-H", "2400",  -- 高さを明示的に指定
          }
        end,
      },
    },
  },
  keys = {
    {
      "<leader>mi",
      function()
        local img = require("snacks.image")
        local doc = img.config.doc

        -- 現在の値を退避
        local old_w, old_h = doc.max_width, doc.max_height

        -- 手動表示のときだけ画面いっぱいに
        doc.max_width  = vim.o.columns       -- 端末の列数
        doc.max_height = vim.o.lines - 2     -- 端末の行数から少し余白

        Snacks.image.hover()

        -- 元に戻す（インライン表示用に 120x60 を維持）
        doc.max_width, doc.max_height = old_w, old_h
      end,
      desc = "Show image at cursor (large)",
    },
  },
}

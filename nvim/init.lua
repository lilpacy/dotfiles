-- Treesitter非同期パース設定
-- 注: 以前はmarkdownクラッシュ回避のため同期パースを強制していたが、
-- nvim-treesitter.configsベースの設定に移行したため無効化して様子見
-- vim.g._ts_force_sync_parsing = true

-- Neovim 0.11+のデフォルトMenuPopup Autocmdを無効化
-- nvim_clear_autocmdsはgroup未指定だとグループなしのautocmdしか消さないため、
-- nvim_get_autocmds + nvim_del_autocmdで全削除する必要がある
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    local acmds = vim.api.nvim_get_autocmds({ event = 'MenuPopup' })
    for _, ac in ipairs(acmds) do
      vim.api.nvim_del_autocmd(ac.id)
    end
  end,
})

-- 基本設定を読み込み
require("config.options")

-- キーマップを読み込み
require("config.keymaps")

-- プラグインマネージャーを読み込み
require("config.lazy")


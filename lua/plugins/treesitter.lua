-- Customize Treesitter
-- Neovim 0.12.4 内置 treesitter highlighter 有 bug，禁用 treesitter 相关插件
-- 等 Neovim 更新后移除所有 enabled = false 即可恢复

---@type LazySpec
return {
  { "nvim-treesitter/nvim-treesitter", enabled = false },
  { "JoosepAlviste/nvim-ts-context-commentstring", enabled = false },
}

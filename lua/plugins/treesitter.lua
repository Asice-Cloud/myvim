-- Customize Treesitter
-- Neovim 0.12.4 内置 treesitter highlighter 有 bug，禁用 nvim-treesitter 插件
-- 等 Neovim 更新后移除 enabled = false 即可恢复

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  enabled = false,
}

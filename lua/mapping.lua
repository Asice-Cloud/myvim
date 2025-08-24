-- Open compiler
vim.api.nvim_set_keymap("n", "<F6>", "<cmd>CompilerOpen<cr>", { noremap = true, silent = true })

-- Redo last selected option
vim.api.nvim_set_keymap(
  "n",
  "<S-F6>",
  "<cmd>CompilerStop<cr>" -- (Optional, to dispose all tasks before redo)
    .. "<cmd>CompilerRedo<cr>",
  { noremap = true, silent = true }
)

-- Toggle compiler results
-- 开关项目文件树
vim.keymap.set({ "v", "n" }, "gsp", "<cmd>NvimTreeFindFileToggle<CR>", { silent = true, desc = "Toggle Nvim Tree" })
-- 开关大纲视图
vim.keymap.set({ "v", "n" }, "gso", "<cmd>AerialToggle!<CR>", { desc = "Toggle aerial outline" })
-- 查找类型定义
vim.keymap.set({ "v", "n" }, "gy", "<cmd>Telescope lsp_type_definitions<CR>", { desc = "Goto type definition" })

vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "Goto definition" })

-- Find Words (Telescope live_grep)
vim.keymap.set("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "Find Words" })
vim.api.nvim_set_keymap("n", "<C-F6>", "<cmd>CompilerToggleResults<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", ":", "<cmd>FineCmdline<CR>", { noremap = true })
if pcall(require, "cmake-tools") then
  vim.api.nvim_set_keymap(
    "n",
    "<F4>",
    "<cmd>wa<CR><cmd>if luaeval('require\"cmake-tools\".is_cmake_project()')|call execute('CMakeRunCurrentFile')|else|call execute('TermExec cmd=./run.sh')|endif<CR>",
    { noremap = true, silent = true }
  )
else
  vim.api.nvim_set_keymap(
    "n",
    "<F4>",
    "<cmd>wa<CR><cmd>call execute('TermExec cmd=./run.sh')|endif<CR>",
    { noremap = true, silent = true }
  )
end

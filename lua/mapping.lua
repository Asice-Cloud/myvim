-- Ctrl+[ 切换到上一个 buffer，Ctrl+] 切换到下一个 buffer
vim.keymap.set("n", "<C-z>", ":bprevious<CR>", { noremap = true, silent = true, desc = "上一个文件" })
vim.keymap.set("n", "<C-x>", ":bnext<CR>", { noremap = true, silent = true, desc = "下一个文件" })

-- Redo last selected option
vim.api.nvim_set_keymap(
  "n",
  "<S-F6>",
  "<cmd>CompilerStop<cr>" -- (Optional, to dispose all tasks before redo)
    .. "<cmd>CompilerRedo<cr>",
  { noremap = true, silent = true }
)

-- 禁用普通模式下的 q 键录制宏
vim.keymap.set("n", "q", "<Nop>")

-- 用 F5 代替 q 录制宏
vim.keymap.set("n", "<F3>", "q", { noremap = true })

-- Toggle compiler results
-- 开关项目文件树
vim.keymap.set({ "v", "n" }, "gsp", "<cmd>NvimTreeFindFileToggle<CR>", { silent = true, desc = "Toggle Nvim Tree" })
-- 开关大纲视图
vim.keymap.set({ "v", "n" }, "gso", "<cmd>AerialToggle!<CR>", { desc = "Toggle aerial outline" })
-- 查找类型定义
vim.keymap.set({ "v", "n" }, "gy", "<cmd>Telescope lsp_type_definitions<CR>", { desc = "Goto type definition" })

-- gd 查找定义
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

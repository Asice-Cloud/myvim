vim.keymap.set("n", "<Esc>", "<Esc>", { desc = "Force Esc to remain Esc in normal mode", noremap = true })
-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  vim.fn.system(
    {
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath
    }
  )
end
vim.opt.rtp:prepend(lazypath)
-- 设置字体
vim.opt.guifont = "JetBrainsMono Nerd Font Mono:h17"

vim.g.neovide_remember_window_size = true
local VimExtConfig = [[ highlight Normal guibg=NONE ctermbg=None ]]
vim.cmd(VimExtConfig)
vim.g.neovide_transparency = 0.65

-- 设置Neo-tree透明背景
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { bg = "NONE" })
  end,
})

-- 立即应用透明设置
vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { bg = "NONE" })

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo(
    {{("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg"}, {"Press any key to exit...", "MoreMsg"}},
    true,
    {}
  )
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"
require "polish"
require "mapping"

require("notify").setup {
  background_colour = "#000000",
}

-- 将 Shift+F7 映射到打开新终端窗口的函数
vim.keymap.set("n", "<S-n>", ":terminal<CR>", { noremap = true, silent = true })

-- F10 compile file

function CompileAndRunFile()
  -- 获取当前文件路径、文件名和文件类型
  local filepath = vim.fn.expand "%:p" -- 获取文件的完整路径
  local filename = vim.fn.expand "%:t:r" -- 获取不带扩展名的文件名
  local filetype = vim.bo.filetype

  -- 设置输出目录和生成的可执行文件路径
  local output_dir = "build/bin"
  local output_file = string.format("%s/%s", output_dir, filename)

  -- 如果目录不存在，创建它
  vim.fn.mkdir(output_dir, "p")

  -- 初始化编译和运行命令
  local compile_cmd = ""
  local run_cmd = ""

  -- 根据文件类型选择编译器
  if filetype == "cpp" then
    compile_cmd = string.format("clang++ -std=c++23 -o %s %s -O2", output_file, filepath)
    run_cmd = string.format("./%s", output_file)
  elseif filetype == "cuda" then
    compile_cmd = string.format("nvcc -ccbin g++-14 -o %s %s -O2 -Wno-deprecated-gpu-targets ", output_file, filepath)
    run_cmd = string.format("./%s", output_file)
  elseif filetype == "c" then
    compile_cmd = string.format("clang -std=c2x -o %s %s -O2", output_file, filepath)
    run_cmd = string.format("./%s", output_file)
  elseif filetype == "lua" then
    run_cmd = string.format("lua %s", filepath)
  elseif filetype == "go" then
    run_cmd = string.format("go run %s", filepath)
  elseif filetype == "javascript" then
    run_cmd = string.format("node %s", filepath)
  elseif filetype == "java" then
    compile_cmd = string.format("javac -d %s %s", output_dir, filepath)
    run_cmd = string.format("java -cp %s %s", output_dir, filename)
  elseif filetype == "python" then
    run_cmd = string.format("python3 %s", filepath)
  elseif filetype == "rust" then
    -- 如果当前目录有 Cargo.toml，则用 release 模式
    local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
    if cargo_toml ~= "" then
      compile_cmd = "cargo build --release"
      run_cmd = "cargo run --release"
    else
      -- 单文件 rust
      compile_cmd = string.format("rustc %s -o %s", filepath, output_file)
      run_cmd = string.format("./%s", output_file)
    end
  else
    vim.notify("Unsupported filetype: " .. filetype, vim.log.levels.ERROR)
    return vim.cmd "w"
  end

  --vim.api.nvim_set_hl(0, "StatusLine", { bg = "gray", fg = "white" })
  --vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "gray", fg = "gray" })
  -- 创建浮动终端窗口的函数
  function open_floating_terminal(cmd)
    local buf = vim.api.nvim_create_buf(false, true) -- 创建一个新的空缓冲区
    local width = vim.o.columns
    local height = vim.o.lines
    local win_height = math.ceil(height * 0.6)
    local win_width = math.ceil(width * 0.8)
    local row = math.ceil((height - win_height) / 3)
    local col = math.ceil((width - win_width) / 2)

    local opts = {
      style = "minimal",
      relative = "editor",
      width = win_width,
      height = win_height,
      row = row,
      col = col,
      border = "rounded",
      noautocmd = true,
    }
    -- 保证浮动窗口边框和内容透明
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })

    local win = vim.api.nvim_open_win(buf, true, opts)

    if cmd and cmd ~= "" then
      vim.fn.termopen(cmd)
      vim.api.nvim_command "startinsert"
    end
  end

  -- 执行编译命令（如果存在）
  if compile_cmd ~= "" then
    local compile_result = vim.fn.system(compile_cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("Compilation failed" .. compile_result, vim.log.levels.ERROR)
      return
    else
      vim.notify("Compilation successful", vim.log.levels.INFO)
    end
  end

  -- 运行生成的可执行文件或脚本
  open_floating_terminal(run_cmd)
end

vim.api.nvim_set_keymap("n", "<F8>", ":lua CompileAndRunFile()<CR>", { noremap = true, silent = true })

-- F6: 编译并运行（带调试信息，兼容 nvim-dap 断点）
function CompileAndRunWithDebug()
  local filepath = vim.fn.expand "%:p"
  local filename = vim.fn.expand "%:t:r"
  local filetype = vim.bo.filetype
  local output_dir = "build/bin"
  local output_file = string.format("%s/%s", output_dir, filename)
  vim.fn.mkdir(output_dir, "p")
  local compile_cmd = ""
  local run_cmd = ""

  if filetype == "cpp" then
    compile_cmd = string.format("g++ -g -O0 -o %s %s", output_file, filepath)
    run_cmd = string.format("%s", output_file)
  elseif filetype == "c" then
    compile_cmd = string.format("gcc -g -O0 -o %s %s", output_file, filepath)
    run_cmd = string.format("%s", output_file)
  elseif filetype == "rust" then
    local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
    if cargo_toml ~= "" then
      compile_cmd = ""
      run_cmd = "cargo build && cargo run"
    else
      compile_cmd = string.format("rustc -g %s -o %s", filepath, output_file)
      run_cmd = string.format("./%s", output_file)
    end
  elseif filetype == "go" then
    compile_cmd = ""
    run_cmd = string.format("go run %s", filepath)
  elseif filetype == "java" then
    compile_cmd = string.format("javac -g -d %s %s", output_dir, filepath)
    run_cmd = string.format("java -cp %s %s", output_dir, filename)
  else
    vim.notify("Unsupported filetype: " .. filetype, vim.log.levels.ERROR)
    return
  end

  if compile_cmd ~= "" then
    local compile_result = vim.fn.system(compile_cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("Compilation failed: " .. compile_result, vim.log.levels.ERROR)
      return
    else
      vim.notify("Compilation successful", vim.log.levels.INFO)
    end
  end

  if run_cmd ~= "" then vim.cmd("belowright split | terminal " .. run_cmd) end
end

vim.api.nvim_set_keymap("n", "<F6>", ":lua CompileAndRunWithDebug()<CR>", { noremap = true, silent = true })

--debug configuration
-- debug for c cpp rust
local dap = require "dap"
dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
}
dap.configurations.c = {
  {
    name = "Launch",
    type = "gdb",
    request = "launch",
    program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = false,
  },
  {
    name = "Select and attach to process",
    type = "gdb",
    request = "attach",
    program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
    pid = function()
      local name = vim.fn.input "Executable name (filter): "
      return require("dap.utils").pick_process { filter = name }
    end,
    cwd = "${workspaceFolder}",
  },
  {
    name = "Attach to gdbserver :1234",
    type = "gdb",
    request = "attach",
    target = "localhost:1234",
    program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
    cwd = "${workspaceFolder}",
  },
}

-- debug for golang
dap.adapters.delve = {
  type = "server",
  port = "${port}",
  executable = {
    command = "dlv",
    args = { "dap", "-l", "127.0.0.1:${port}" },
    -- add this if on windows, otherwise server won't open successfully
    -- detached = false
  },
}

-- https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md
dap.configurations.go = {
  {
    type = "delve",
    name = "Debug",
    request = "launch",
    program = "${file}",
  },
  {
    type = "delve",
    name = "Debug test", -- configuration for debugging test files
    request = "launch",
    mode = "test",
    program = "${file}",
  },
  -- works with go.mod packages and sub packages
  {
    type = "delve",
    name = "Debug test (go.mod)",
    request = "launch",
    mode = "test",
    program = "./${relativeFileDirname}",
  },
}
--debug for js
require("dap").adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = "node",
    -- 💀 Make sure to update this path to point to your installation
    args = { "~/js-debug/src/dapDebugServer.js", "${port}" },
  },
}

-- clangd config
-- clangd 配置
local lspconfig = require "lspconfig"

lspconfig.clangd.setup {
  cmd = {
    "clangd", -- 确保这行存在
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--header-insertion=iwyu",
    "--fallback-style=llvm",
  },
  init_options = {
    fallbackFlags = {
      "-std=c++23",
      -- "-std=c23",
      "-Wall",
      "-Wextra",
      "-Wpedantic",
      "-Werror",
    },
  },
  filetypes = { "cpp", "cxx", "cc", "h", "hpp", "hxx" },
  root_dir = lspconfig.util.root_pattern(
    "compile_commands.json",
    "compile_flags.txt",
    ".clangd",
    "CMakeLists.txt",
    "Makefile",
    ".git"
  ),
  single_file_support = true,
}

local util = require "lspconfig.util"

-- https://clangd.llvm.org/extensions.html#switch-between-sourceheader
local function switch_source_header(bufnr)
  bufnr = util.validate_bufnr(bufnr)
  local clangd_client = util.get_active_client_by_name(bufnr, "clangd")
  local params = { uri = vim.uri_from_bufnr(bufnr) }
  if clangd_client then
    clangd_client.request("textDocument/switchSourceHeader", params, function(err, result)
      if err then error(tostring(err)) end
      if not result then
        print "Corresponding file cannot be determined"
        return
      end
      vim.api.nvim_command("edit " .. vim.uri_to_fname(result))
    end, bufnr)
  else
    print "method textDocument/switchSourceHeader is not supported by any servers active on the current buffer"
  end
end

local function symbol_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local clangd_client = util.get_active_client_by_name(bufnr, "clangd")
  if not clangd_client or not clangd_client.supports_method "textDocument/symbolInfo" then
    return vim.notify("Clangd client not found", vim.log.levels.ERROR)
  end
  local params = vim.lsp.util.make_position_params()
  clangd_client.request("textDocument/symbolInfo", params, function(err, res)
    if err or #res == 0 then
      -- Clangd always returns an error, there is not reason to parse it
      return
    end
    local container = string.format("container: %s", res[1].containerName) ---@type string
    local name = string.format("name: %s", res[1].name) ---@type string
    vim.lsp.util.open_floating_preview({ name, container }, "", {
      height = 2,
      width = math.max(string.len(name), string.len(container)),
      focusable = false,
      focus = false,
      border = require("lspconfig.ui.windows").default_options.border or "single",
      title = "Symbol Info",
    })
  end, bufnr)
end

local root_files = {
  ".clangd",
  ".clang-tidy",
  ".clang-format",
  "compile_commands.json",
  "compile_flags.txt",
  "configure.ac", -- AutoTools
}

local default_capabilities = {
  textDocument = {
    completion = {
      editsNearCursor = true,
    },
  },
  offsetEncoding = { "utf-8", "utf-16" },
}

return {
  default_config = {
    cmd = { "clangd", "--compile_commands-dir=build", "xc++", "--std=c++23" },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    root_dir = function(fname) return util.root_pattern(unpack(root_files))(fname) or util.find_git_ancestor(fname) end,
    single_file_support = true,
    capabilities = default_capabilities,
  },
  commands = {
    ClangdSwitchSourceHeader = {
      function() switch_source_header(0) end,
      description = "Switch between source/header",
    },
    ClangdShowSymbolInfo = {
      function() symbol_info() end,
      description = "Show symbol info",
    },
  },
  docs = {
    description = [[
https://clangd.llvm.org/installation.html

- **NOTE:** Clang >= 11 is recommended! See [#23](https://github.com/neovim/nvim-lsp/issues/23).
- If `compile_commands.json` lives in a build directory, you should
  symlink it to the root of your source tree.
  ```
  ln -s /path/to/myproject/build/compile_commands.json /path/to/myproject/
  ```
- clangd relies on a [JSON compilation database](https://clang.llvm.org/docs/JSONCompilationDatabase.html)
  specified as compile_commands.json, see https://clangd.llvm.org/installation#compile_commandsjson
]],
    default_config = {
      root_dir = [[
        root_pattern(
          '.clangd',
          '.clang-tidy',
          '.clang-format',
          'compile_commands.json',
          'compile_flags.txt',
          'configure.ac',
          '.git'
        )
      ]],
      capabilities = [[default capabilities, with offsetEncoding utf-8]],
    },
  },
}

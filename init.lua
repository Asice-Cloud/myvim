vim.keymap.set("n", "<Esc>", "<Esc>", {
    desc = "Force Esc to remain Esc in normal mode",
    noremap = true
})

vim.keymap.set("n", "H", "<Nop>", {
    noremap = true,
    silent = true,
    desc = "Disable Shift-H"
})

-- Early filter for specific deprecation messages so they don't appear during
-- plugin startup. Placed here before `lazy` is required so messages emitted
-- during plugin setup can be filtered.
do
    local _notify = vim.notify
    vim.notify = function(msg, level, opts)
        if type(msg) == "string" then
            -- Filter messages that mention the deprecated API used by some plugins
            -- Example: "vim.lsp.get_active_clients() is deprecated. Run ':checkhealth vim.deprecated'..."
            if msg:match "get_active_clients" or msg:match "checkhealth vim%.deprecated" then
                return
            end
            -- Also ignore short deprecation mentions to avoid noisy startup messages
            if msg:match "[Dd]eprecat" and (msg:match "vim%.lsp" or msg:match "get_active_clients") then
                return
            end
        end
        return _notify(msg, level, opts)
    end
end

-- Provide a temporary compatibility shim: if running on Neovim with
-- `vim.lsp.get_clients`, map the deprecated `get_active_clients` to it so
-- plugins calling the old API won't trigger deprecation messages.
if vim.lsp and type(vim.lsp.get_clients) == "function" then
    vim.lsp.get_active_clients = function(filters)
        -- `vim.lsp.get_clients` accepts a table of filters in newer Neovim
        return vim.lsp.get_clients(filters)
    end
end

-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
    -- stylua: ignore
    vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
                   lazypath})
end
vim.opt.rtp:prepend(lazypath)
-- 设置字体
vim.opt.guifont = "FantasqueSansM Nerd Font Mono:h17"

vim.g.neovide_remember_window_size = true
local VimExtConfig = [[ highlight Normal guibg=NONE ctermbg=None ]]
vim.cmd(VimExtConfig)
vim.g.neovide_transparency = 0.65

-- 设置Neo-tree透明背景
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        vim.api.nvim_set_hl(0, "NeoTreeNormal", {
            bg = "NONE"
        })
        vim.api.nvim_set_hl(0, "NeoTreeNormalNC", {
            bg = "NONE"
        })
        vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", {
            bg = "NONE"
        })
        vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", {
            bg = "NONE"
        })
    end
})

-- 立即应用透明设置
vim.api.nvim_set_hl(0, "NeoTreeNormal", {
    bg = "NONE"
})
vim.api.nvim_set_hl(0, "NeoTreeNormalNC", {
    bg = "NONE"
})
vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", {
    bg = "NONE"
})
vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", {
    bg = "NONE"
})

-- validate that lazy is available
if not pcall(require, "lazy") then
    -- stylua: ignore
    vim.api.nvim_echo({{("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg"},
                       {"Press any key to exit...", "MoreMsg"}}, true, {})
    vim.fn.getchar()
    vim.cmd.quit()
end

require "lazy_setup"
require "polish"
require "mapping"

require("notify").setup {
    background_colour = "#000000"
}

-- F8 compile file

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
        compile_cmd = -- string.format("nvcc -ccbin g++-14 -o %s %s -O2 -Wno-deprecated-gpu-targets ", output_file, filepath)
        string.format("nvcc -ccbin g++ -o %s %s -O2 -Wno-deprecated-gpu-targets ", output_file, filepath)
        run_cmd = string.format("./%s", output_file)
    elseif filetype == "c" then
        compile_cmd = string.format("clang -std=c2x -o %s %s -O2", output_file, filepath)
        run_cmd = string.format("./%s", output_file)
    elseif filetype == "lua" then
        run_cmd = string.format("lua %s", filepath)
    elseif filetype == "go" then
        run_cmd = string.format("go run %s", filepath)
    elseif filetype == "javascript" then
        run_cmd = string.format("deno %s", filepath)
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

    -- vim.api.nvim_set_hl(0, "StatusLine", { bg = "gray", fg = "white" })
    -- vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "gray", fg = "gray" })
    -- 创建浮动终端窗口的函数
    local function open_floating_terminal(cmd)
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
            noautocmd = true
        }
        -- 保证浮动窗口边框和内容透明
        vim.api.nvim_set_hl(0, "NormalFloat", {
            bg = "NONE"
        })
        vim.api.nvim_set_hl(0, "FloatBorder", {
            bg = "NONE"
        })

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

    -- 提示可选运行参数并运行（仅在有运行命令时）
    if run_cmd ~= "" then
        -- compute same geometry as open_floating_terminal so the input window matches the terminal
        local width = vim.o.columns
        local height = vim.o.lines
        local term_h = math.ceil(height * 0.6)
        local term_w = math.ceil(width * 0.8)
        local term_row = math.ceil((height - term_h) / 3)
        local term_col = math.ceil((width - term_w) / 2)

        local input_h = 1
        -- make input narrower (70% of terminal width) with a sensible minimum
        local input_w = math.max(40, math.ceil(term_w * 0.7))
        -- horizontally center the input inside the terminal area
        local input_col = term_col + math.floor((term_w - input_w) / 2)
        -- center vertically then shift up ~20% of term height
        local center_row = term_row + math.floor((term_h - input_h) / 2)
        local shift_up = math.ceil(term_h * 0.20)
        local input_row = math.max(term_row, center_row - shift_up)

        local ok, _ = pcall(function()
            -- create a prompt buffer and open a floating window matching the terminal size/pos
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_option(buf, 'buftype', 'prompt')
            vim.fn.prompt_setprompt(buf, "Optional run arguments: ")
            local win_opts = {
                relative = 'editor',
                row = input_row,
                col = input_col,
                width = input_w,
                height = input_h,
                style = 'minimal',
                border = 'rounded',
            }
            local win = vim.api.nvim_open_win(buf, true, win_opts)
            vim.fn.prompt_setcallback(buf, function(input)
                pcall(vim.api.nvim_win_close, win, true)
                pcall(vim.api.nvim_buf_delete, buf, {force = true})
                if input and input ~= "" then
                    run_cmd = run_cmd .. " " .. input
                end
                open_floating_terminal(run_cmd)
            end)
            vim.cmd('startinsert')
        end)
        if not ok then
            -- fallback to simple input
            local extra_args = vim.fn.input("Optional run arguments (append, leave empty for none): ")
            if extra_args and extra_args ~= "" then
                run_cmd = run_cmd .. " " .. extra_args
            end
            open_floating_terminal(run_cmd)
        end
    else
        vim.notify("No run command for this filetype.", vim.log.levels.WARN)
    end
end

vim.api.nvim_set_keymap("n", "<F8>", ":lua CompileAndRunFile()<CR>", {
    noremap = true,
    silent = true
})

-- F6: compile file with debug info for c,cpp,rust 
function CompileAndRunWithDebug()
    local filepath = vim.fn.expand "%:p"
    local filename = vim.fn.expand "%:t:r"
    local filetype = vim.bo.filetype
    local output_dir = "build/bin"
    local outname = filename .. "_debug"
    local output_file = string.format("%s/%s", output_dir, outname)
    vim.fn.mkdir(output_dir, "p")
    local compile_cmd = ""

    if filetype == "cpp" then
        compile_cmd = string.format("clang++ -g -std=c++23 -O0 -o %s %s", output_file, filepath)
    elseif filetype == "c" then
        compile_cmd = string.format("clang -g -std=c2x -O0 -o %s %s", output_file, filepath)
    elseif filetype == "rust" then
        local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
        if cargo_toml ~= "" then
            compile_cmd = "cargo build"
        else
            compile_cmd = string.format("rustc -g %s -o %s", filepath, output_file)
        end
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

end

vim.api.nvim_set_keymap("n", "<F6>", ":lua CompileAndRunWithDebug()<CR>", {
    noremap = true,
    silent = true
})

-- debug configuration
local dap = require "dap"

local function mason_debugpy_python()
    local mason_base = vim.fn.stdpath("data") .. "/mason/packages/debugpy"
    local mason_venv = mason_base .. "/venv/bin/python"
    local mason_bin = mason_base .. "/bin/python"
    if vim.fn.executable(mason_venv) == 1 then
        return mason_venv
    elseif vim.fn.executable(mason_bin) == 1 then
        return mason_bin
    end
    return nil
end

-- debug for python
dap.adapters.python = function(cb, config)
    if config.request == "attach" then
        ---@diagnostic disable-next-line: undefined-field
        local port = (config.connect or config).port
        ---@diagnostic disable-next-line: undefined-field
        local host = (config.connect or config).host or "127.0.0.1"
        cb {
            type = "server",
            port = assert(port, "`connect.port` is required for a python `attach` configuration"),
            host = host,
            options = {
                source_filetype = "python"
            }
        }
    else
        local cmd = mason_debugpy_python()
        if not cmd then
            -- fallback to project venv or system python if mason not found
            local cwd = vim.fn.getcwd()
            if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
                cmd = cwd .. "/.venv/bin/python"
            elseif vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
                cmd = cwd .. "/venv/bin/python"
            else
                cmd = vim.fn.exepath("python3") or vim.fn.exepath("python") or "/usr/bin/python"
            end
        end

        cb {
            type = "executable",
            command = cmd,
            args = {"-m", "debugpy.adapter"},
            options = {
                source_filetype = "python"
            }
        }
    end
end

dap.configurations.python = {{
    -- The first three options are required by nvim-dap
    type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
    request = "launch",
    name = "Launch file",

    -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

    program = "${file}", -- This configuration will launch the current file if used.
    pythonPath = function()
        -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
        -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
        -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
        local cwd = vim.fn.getcwd()
        if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
            return cwd .. "/venv/bin/python"
        elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
            return cwd .. "/.venv/bin/python"
        else
            return "/usr/bin/python"
        end
    end
}}

-- debug for c cpp rust

-- dap.adapters.gdb = {
--     type = "executable",
--     command = "gdb",
--     args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
-- }
-- dap.configurations.c = {
--     {
--         name = "[GDB]:Launch",
--         type = "gdb",
--         request = "launch",
--         program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
--         cwd = "${workspaceFolder}",
--         stopAtBeginningOfMainSubprogram = false,
--     },
--     {
--         name = "[GDB]:Select and attach to process",
--         type = "gdb",
--         request = "attach",
--         program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
--         pid = function()
--             local name = vim.fn.input "Executable name (filter): "
--             return require("dap.utils").pick_process { filter = name }
--         end,
--         cwd = "${workspaceFolder}",
--     },
--     {
--         name = "[GDB]:Attach to gdbserver :1234",
--         type = "gdb",
--         request = "attach",
--         target = "localhost:1234",
--         program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
--         cwd = "${workspaceFolder}",
--     },
-- }

-- dap.configurations.cpp = dap.configurations.c
-- dap.configurations.rust = dap.configurations.c

-- debug for golang
dap.adapters.delve = {
    type = "server",
    port = "${port}",
    executable = {
        command = "dlv",
        args = {"dap", "-l", "127.0.0.1:${port}"}
        -- add this if on windows, otherwise server won't open successfully
        -- detached = false
    }
}

-- https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md
dap.configurations.go = {{
    type = "delve",
    name = "Debug",
    request = "launch",
    program = "${file}"
}, {
    type = "delve",
    name = "Debug test", -- configuration for debugging test files
    request = "launch",
    mode = "test",
    program = "${file}"
}, -- works with go.mod packages and sub packages
{
    type = "delve",
    name = "Debug test (go.mod)",
    request = "launch",
    mode = "test",
    program = "./${relativeFileDirname}"
}}

-- debug for js
require("dap").adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
        command = "js-debug-adapter",
        args = {"${port}"}
    }
}
dap.configurations.javascript = {{
    type = "pwa-node",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    cwd = "${workspaceFolder}"
}, {
    type = "pwa-node",
    request = "attach",
    name = "Attach",
    processId = require("dap.utils").pick_process,
    cwd = "${workspaceFolder}"
}}

-- -- detect codelldb adapter path (Mason or system)
-- simple shell-style arg parser (handles single/double quotes and escapes)
local function parse_cmdline(s)
    if not s or s == "" then return {} end
    local res = {}
    local i = 1
    local len = #s
    while i <= len do
        -- skip spaces
        while i <= len and s:sub(i, i):match('%s') do i = i + 1 end
        if i > len then break end
        local c = s:sub(i, i)
        local buf = {}
        if c == '"' or c == "'" then
            local quote = c
            i = i + 1
            while i <= len do
                local ch = s:sub(i, i)
                if ch == '\\' then
                    -- escape next char
                    i = i + 1
                    if i <= len then table.insert(buf, s:sub(i, i)) end
                elseif ch == quote then
                    i = i + 1
                    break
                else
                    table.insert(buf, ch)
                end
                i = i + 1
            end
        else
            while i <= len do
                local ch = s:sub(i, i)
                if ch:match('%s') then break end
                if ch == '\\' then
                    i = i + 1
                    if i <= len then table.insert(buf, s:sub(i, i)) end
                else
                    table.insert(buf, ch)
                end
                i = i + 1
            end
        end
        table.insert(res, table.concat(buf))
    end
    return res
end

local adapter_path = nil
local mason_base = vim.fn.stdpath("data") .. "/mason/packages/codelldb"
local candidate1 = mason_base .. "/extension/adapter/codelldb"
local candidate2 = mason_base .. "/adapter/codelldb"
if vim.loop.fs_stat(candidate1) then
    adapter_path = candidate1
elseif vim.loop.fs_stat(candidate2) then
    adapter_path = candidate2
else
    -- try to find codelldb in PATH
    local inpath = vim.fn.exepath("codelldb")
    if inpath ~= "" then
        adapter_path = inpath
    end
end

if adapter_path and vim.loop.fs_stat(adapter_path) then
    dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
            command = adapter_path,
            args = {"--port", "${port}"}
        }
    }

    dap.configurations.cpp = dap.configurations.cpp or {}
    table.insert(dap.configurations.cpp, {
        name = "Launch codelldb",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = true
    })
    -- Launch with args (quote-aware parsing)
    table.insert(dap.configurations.cpp, {
        name = "Launch codelldb (with args)",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        args = function()
            local input = vim.fn.input("Program args: ")
            return parse_cmdline(input)
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = true
    })
    dap.configurations.c = dap.configurations.cpp

    dap.configurations.rust = dap.configurations.rust or {}
    table.insert(dap.configurations.rust, {
        name = "Debug (codelldb) - cargo debug",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable (default target/debug/): ", vim.fn.getcwd() .. "/target/debug/",
                "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = true
    })
    -- Rust: launch with args (quote-aware parsing)
    table.insert(dap.configurations.rust, {
        name = "Debug (codelldb) - cargo debug (with args)",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable (default target/debug/): ", vim.fn.getcwd() .. "/target/debug/", "file")
        end,
        args = function()
            local input = vim.fn.input("Program args: ")
            return parse_cmdline(input)
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = true
    })
else
    -- adapter_path not found; do not register codelldb to avoid errors
    vim.schedule(function()
        vim.notify("codelldb adapter not found; skipping codelldb DAP registration", vim.log.levels.WARN)
    end)
end

-- clangd config
-- clangd 配置
local lspconfig = require "lspconfig"

lspconfig.clangd.setup {
    cmd = {"clangd", -- 确保这行存在
    "--background-index", "--clang-tidy", "--completion-style=detailed", "--function-arg-placeholders",
           "--header-insertion=iwyu", "--fallback-style=llvm"},
    init_options = {
        fallbackFlags = {"-std=c++23", -- "-std=c23",
        "-Wall", "-Wextra", "-Wpedantic", "-Werror"}
    },
    filetypes = {"cpp", "cxx", "cc", "h", "hpp", "hxx"},
    root_dir = lspconfig.util.root_pattern("compile_commands.json", "compile_flags.txt", ".clangd", "CMakeLists.txt",
        "Makefile", ".git"),
    single_file_support = true
}

local util = require "lspconfig.util"

local function get_python_path(workspace)
    if vim.env.VIRTUAL_ENV then
        return vim.env.VIRTUAL_ENV .. "/bin/python"
    end

    local candidates = {".venv", "venv", "env"}
    for _, name in ipairs(candidates) do
        local full = util.path.join(workspace, name)
        local st = vim.loop.fs_stat(full)
        if st and st.type == "directory" then
            local py = util.path.join(full, "bin", "python")
            if vim.loop.fs_stat(py) then
                return py
            end
        end
    end

    return vim.fn.exepath "python3" or vim.fn.exepath "python" or "/usr/bin/python3"
end

---@type any
local pyright_opts = {
    before_init = function(params)
        local workspace = vim.uri_to_fname(params.rootUri)
        local python_path = get_python_path(workspace)
        params.settings = params.settings or {}
        params.settings.python = params.settings.python or {}
        params.settings.python.pythonPath = python_path
    end,
    settings = {
        python = {
            analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "basic",
                useLibraryCodeForTypes = true
            }
        }
    }
}

-- https://clangd.llvm.org/extensions.html#switch-between-sourceheader
local function switch_source_header(bufnr)
    bufnr = util.validate_bufnr(bufnr)
    local clangd_client = util.get_active_client_by_name(bufnr, "clangd")
    local params = {
        uri = vim.uri_from_bufnr(bufnr)
    }
    if clangd_client then
        clangd_client.request("textDocument/switchSourceHeader", params, function(err, result)
            if err then
                error(tostring(err))
            end
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
        vim.lsp.util.open_floating_preview({name, container}, "", {
            height = 2,
            width = math.max(string.len(name), string.len(container)),
            focusable = false,
            focus = false,
            border = require("lspconfig.ui.windows").default_options.border or "single",
            title = "Symbol Info",
            -- stronger blend so the inner background becomes visually transparent
            winblend = 40,
            winhighlight = "Normal:MacroFloatNormal,NormalFloat:MacroFloatNormal,FloatBorder:MacroFloatBorder,FloatTitle:MacroFloatTitle"
        })
    end, bufnr)
end

local root_files = {".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt",
                    "configure.ac" -- AutoTools
}

local default_capabilities = {
    textDocument = {
        completion = {
            editsNearCursor = true
        }
    },
    offsetEncoding = {"utf-8", "utf-16"}
}

return {
    default_config = {
        cmd = {"clangd", "--compile_commands-dir=build", "xc++", "--std=c++23"},
        filetypes = {"c", "cpp", "objc", "objcpp", "cuda", "proto"},
        root_dir = function(fname)
            return util.root_pattern(unpack(root_files))(fname) or util.find_git_ancestor(fname)
        end,
        single_file_support = true,
        capabilities = default_capabilities
    },
    commands = {
        ClangdSwitchSourceHeader = {
            function()
                switch_source_header(0)
            end,
            description = "Switch between source/header"
        },
        ClangdShowSymbolInfo = {
            function()
                symbol_info()
            end,
            description = "Show symbol info"
        }
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
            capabilities = [[default capabilities, with offsetEncoding utf-8]]
        }
    }
}

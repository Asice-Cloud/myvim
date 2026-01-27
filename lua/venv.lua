-- ~/.config/nvim/lua/venv.lua
local M = {}

local uv = vim.loop
local function is_dir(path)
    local stat = uv.fs_stat(path)
    return stat and stat.type == "directory"
end

local function file_exists(path) return uv.fs_stat(path) ~= nil end

local function prepend_path(p)
    local cur = vim.env.PATH or ""
    if not cur:match(p) then vim.env.PATH = p .. ":" .. cur end
end

-- 返回 venv 的 python 可执行路径，或 nil
function M.find_venv_python(workspace)
    if vim.env.VIRTUAL_ENV and file_exists(vim.env.VIRTUAL_ENV .. "/bin/python") then
        return vim.env.VIRTUAL_ENV .. "/bin/python"
    end

    local candidates = { ".venv", "venv", "env" }
    for _, name in ipairs(candidates) do
        local full = workspace .. "/" .. name
        if is_dir(full) then
            local py = full .. "/bin/python"
            if file_exists(py) then return py end
        end
    end

    return nil
end

-- 激活 venv（设置环境变量 & PATH & python3_host_prog）
function M.activate_venv_for_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == "" then return end
    local workspace = vim.fn.getcwd() -- 或者使用更复杂的 workspace 寻找
    local py = M.find_venv_python(workspace)
    if not py then return end

    local venv_dir = py:match "(.+)/bin/python$"
    if not venv_dir then return end

    -- 设置 VIRTUAL_ENV 环境变量
    vim.env.VIRTUAL_ENV = venv_dir

    -- 把 venv bin prepend 到 PATH
    prepend_path(venv_dir .. "/bin")

    -- 如果你用 neovim 的 python host（pynvim），可以设置 python3_host_prog
    vim.g.python3_host_prog = venv_dir .. "/bin/python"

    -- Optionally, print a small message
    vim.notify("Activated venv: " .. venv_dir, vim.log.levels.DEBUG)

    return py, venv_dir
end

-- autocmd: 打开 python 文件时自动激活
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "LspAttach" }, {
    pattern = { "*.py" },
    callback = function(args)
        -- 激活并在 pyright 的 before_init 中注入（如果你已实现 before_init）
        local py, venv = M.activate_venv_for_buffer(args.buf)
        vim.notify("Activated venv: " .. (venv or "none"), vim.log.levels.DEBUG)
        -- 如果想，触发 LSP 重启以让 pyright 重新使用新的环境（可选）
        if py then
            -- 延迟少量时间再重启，避免频繁重启
            vim.defer_fn(function() pcall(vim.cmd, "LspRestart") end, 200)
        end
    end,
})

return M

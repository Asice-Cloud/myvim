-- Customize Mason plugins

---@type LazySpec
return {
    {
        "williamboman/mason.nvim",
        opts = {
            ui = {
                border = "rounded",
                winblend = 0,
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        },
    },
    -- use mason-lspconfig to configure LSP installations
    {
        "williamboman/mason-lspconfig.nvim",
        -- overrides `require("mason-lspconfig").setup(...)`
        opts = {
            ensure_installed = {
                -- add more arguments for adding more language servers
                -- (lua_ls removed to use system-installed lua-language-server instead of Mason binary)
            },
        },
    },
    -- use mason-null-ls to configure Formatters/Linter installation for null-ls sources
    {
        "jay-babu/mason-null-ls.nvim",
        -- overrides `require("mason-null-ls").setup(...)`
        opts = {
            ensure_installed = {
                "stylua",
                -- add more arguments for adding more null-ls sources
            },
        },
    },
    {
        "jay-babu/mason-nvim-dap.nvim",
        -- overrides `require("mason-nvim-dap").setup(...)`
        opts = {
            ensure_installed = {
                -- "python",
                -- add more arguments for adding more debuggers
            },
        },
    },
}

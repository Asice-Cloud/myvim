-- You can also add or configure plugins by creating files in this `plugins/` folder
-- Here are some examples:
---@type LazySpec
return {
    plugins = {
        init = {},
    },
    -- Neo-tree 配置：显示隐藏文件
    {
        "nvim-neo-tree/neo-tree.nvim",
        opts = {
            filesystem = {
                filtered_items = {
                    visible = true, -- 显示过滤的项目
                    hide_dotfiles = false, -- 显示以 . 开头的文件
                    hide_gitignored = false, -- 显示被 git 忽略的文件
                    hide_hidden = false, -- 在 Windows 上显示隐藏文件
                },
                follow_current_file = {
                    enabled = true, -- 自动跟随当前文件
                    leave_dirs_open = false, -- 关闭其他目录
                },
                group_empty_dirs = false, -- 不合并空目录
                hijack_netrw_behavior = "open_default", -- 劫持 netrw
                use_libuv_file_watcher = true, -- 使用文件监控
            },
            window = {
                position = "left",
                width = 30,
                mapping_options = {
                    noremap = true,
                    nowait = true,
                },
            },
            -- 添加透明背景设置
            renderers = {
                directory = {
                    { "indent" },
                    { "icon" },
                    { "current_filter" },
                    {
                        "container",
                        content = {
                            { "name", zindex = 10 },
                            { "clipboard", zindex = 10 },
                            {
                                "diagnostics",
                                errors_only = true,
                                zindex = 20,
                                align = "right",
                                hide_when_expanded = true,
                            },
                            { "git_status", zindex = 20, align = "right", hide_when_expanded = true },
                        },
                    },
                },
                file = {
                    { "indent" },
                    { "icon" },
                    {
                        "container",
                        content = {
                            { "name", zindex = 10 },
                            { "clipboard", zindex = 10 },
                            { "bufnr", zindex = 10 },
                            { "modified", zindex = 20, align = "right" },
                            { "diagnostics", zindex = 20, align = "right", hide_when_expanded = true },
                            { "git_status", zindex = 20, align = "right" },
                        },
                    },
                },
            },
            default_component_configs = {
                container = {
                    enable_character_fade = true,
                },
                indent = {
                    indent_size = 4,
                    padding = 1, -- 额外填充
                    -- indent guides
                    with_markers = true,
                    indent_marker = "│",
                    last_indent_marker = "└",
                    highlight = "NeoTreeIndentMarker",
                    -- expander config, needed for nesting files
                    with_expanders = nil, -- 如果 nil 和 file nesting 被启用，将启用 expanders
                    expander_collapsed = "",
                    expander_expanded = "",
                    expander_highlight = "NeoTreeExpander",
                },
                icon = {
                    folder_closed = "",
                    folder_open = "",
                    folder_empty = "󰜌",
                    -- 下一行仅在 nvim-web-devicons 不可用时应用
                    default = "*",
                    highlight = "NeoTreeFileIcon",
                },
                modified = {
                    symbol = "[+]",
                    highlight = "NeoTreeModified",
                },
                name = {
                    trailing_slash = false,
                    use_git_status_colors = true,
                    highlight = "NeoTreeFileName",
                },
                git_status = {
                    symbols = {
                        -- 改名状态
                        added = "", -- 或者 "✚"，但这已经是 git status 中的默认值了
                        modified = "", -- 或者 "✹"
                        deleted = "✖", -- 这只能在 git status 中显示
                        renamed = "󰁕", -- 这只能在 git status 中显示
                        -- git status 类型
                        untracked = "",
                        ignored = "",
                        unstaged = "󰄱",
                        staged = "",
                        conflict = "",
                    },
                },
                file_size = {
                    enabled = true,
                    required_width = 64, -- 最小窗口宽度来显示这个栏
                },
                type = {
                    enabled = true,
                    required_width = 122, -- 最小窗口宽度来显示这个栏
                },
                last_modified = {
                    enabled = true,
                    required_width = 88, -- 最小窗口宽度来显示这个栏
                },
                created = {
                    enabled = true,
                    required_width = 110, -- 最小窗口宽度来显示这个栏
                },
                symlink_target = {
                    enabled = false,
                },
            },
        },
    },
    -- == Examples of Adding Plugins ==

    "andweeb/presence.nvim",
    {
        "ray-x/lsp_signature.nvim",
        event = "BufRead",
        config = function() require("lsp_signature").setup() end,
    },
    -- == Examples of Overriding Plugins ==

    -- customize alpha options
    {
        "goolord/alpha-nvim",
        opts = function(_, opts)
            -- customize the dashboard header
            opts.section.header.val = {
                "     █████  ███████  ██    ██████  ███████",
                "    ██   ██ ██       ██  ██        ██     ",
                "    ███████ ███████  ██  ██        ███████",
                "    ██   ██      ██  ██  ██        ██     ",
                "    ██   ██ ███████  ██    ██████  ███████",
                " ",
                "  ██████  ██       █████    ██    ██        ██",
                "██        ██     ██     ██  ██    ██        ██",
                "██        ██     ██     ██  ██    ██   ███████",
                "██        ██     ██     ██  ██    ██   ██   ██",
                "  ██████  ██████   █████     ██████    ███████",
            }
            return opts
        end,
    },
    {
        "Civitasv/cmake-tools.nvim",
        config = function()
            require("cmake-tools").setup {
                cmake_command = "cmake", -- this is used to specify cmake command path
                cmake_regenerate_on_save = false, -- auto generate when save CMakeLists.txt
                cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" }, -- this will be passed when invoke `CMakeGenerate`
                cmake_build_options = {}, -- this will be passed when invoke `CMakeBuild`
                -- support macro expansion:
                --       ${kit}
                --       ${kitGenerator}
                --       ${variant:xx}
                -- cmake_build_directory = "out/${variant:buildType}", -- this is used to specify generate directory for cmake, allows macro expansion
                cmake_build_directory = "build", -- this is used to specify generate directory for cmake, allows macro expansion
                cmake_soft_link_compile_commands = false, -- this will automatically make a soft link from compile commands file to project root dir
                cmake_compile_commands_from_lsp = true, -- this will automatically set compile commands file location using lsp, to use it, please set `cmake_soft_link_compile_commands` to false
                cmake_kits_path = nil, -- this is used to specify global cmake kits path, see CMakeKits for detailed usage
                cmake_variants_message = {
                    short = {
                        show = true,
                    }, -- whether to show short message
                    long = {
                        show = true,
                        max_length = 80,
                    }, -- whether to show long message
                },
                cmake_dap_configuration = {
                    -- debug settings for cmake
                    name = "cpp",
                    type = "codelldb",
                    request = "launch",
                    stopOnEntry = false,
                    runInTerminal = true,
                    console = "integratedTerminal",
                },
                cmake_executor = {
                    -- executor to use
                    name = "quickfix", -- name of the executor
                    opts = {}, -- the options the executor will get, possible values depend on the executor type. See `default_opts` for possible values.
                    default_opts = {
                        -- a list of default and possible values for executors
                        quickfix = {
                            show = "always", -- "always", "only_on_error"
                            position = "botright", -- "bottom", "top", "belowright"
                            size = 10,
                            encoding = "utf-8",
                            auto_close_when_success = true, -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
                        },
                        toggleterm = {
                            direction = "horizontal", -- 'vertical' | 'horizontal' | 'tab' | 'float'
                            close_on_exit = true, -- whether close the terminal when exit
                            auto_scroll = true, -- whether auto scroll to the bottom
                        },
                        overseer = {},
                        terminal = {
                            name = "CMake Terminal",
                            prefix_name = "[CMakeTools]: ", -- This must be included and must be unique, otherwise the terminals will not work. Do not use a simple spacebar " ", or any generic name
                            split_direction = "horizontal", -- "horizontal", "vertical"
                            split_size = 6,
                            -- Window handling
                            single_terminal_per_instance = true, -- Single viewport, multiple windows
                            single_terminal_per_tab = true, -- Single viewport per tab
                            keep_terminal_static_location = true, -- Static location of the viewport if avialable
                            -- Running Tasks
                            start_insert = false, -- If you want to enter terminal with :startinsert upon using :CMakeRun
                            focus = false, -- Focus on terminal when cmake task is launched.
                            do_not_add_newline = true, -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
                        },
                    },
                },
                cmake_runner = {
                    -- name = "terminal",
                    name = "toggleterm",
                    opts = {},
                    default_opts = {
                        -- a list of default and possible values for runners
                        quickfix = {
                            show = "always", -- "always", "only_on_error"
                            position = "belowright", -- "bottom", "top"
                            size = 10,
                            encoding = "utf-8",
                            auto_close_when_success = true, -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
                        },
                        toggleterm = {
                            -- direction = "horizontal", -- 'vertical' | 'horizontal' | 'tab' | 'float'
                            direction = "tab", -- 'vertical' | 'horizontal' | 'tab' | 'float'
                            close_on_exit = false, -- whether close the terminal when exit
                            auto_scroll = true, -- whether auto scroll to the bottom
                            singleton = true, -- single instance, autocloses the opened one, if present
                        },
                        overseer = {},
                        terminal = {
                            name = "CMake Terminal",
                            prefix_name = "[CMakeTools]: ", -- This must be included and must be unique, otherwise the terminals will not work. Do not use a simple spacebar " ", or any generic name
                            split_direction = "horizontal", -- "horizontal", "vertical"
                            split_size = 6,
                            -- Window handling
                            single_terminal_per_instance = true, -- Single viewport, multiple windows
                            single_terminal_per_tab = true, -- Single viewport per tab
                            keep_terminal_static_location = true, -- Static location of the viewport if avialable
                            -- Running Tasks
                            start_insert = false, -- If you want to enter terminal with :startinsert upon using :CMakeRun
                            focus = false, -- Focus on terminal when cmake task is launched.
                            do_not_add_newline = false, -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
                        },
                    },
                },
                cmake_notifications = {
                    runner = {
                        enabled = false,
                    },
                    executor = {
                        enabled = false,
                    },
                    spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }, -- icons used for progress display
                    refresh_rate_ms = 100, -- how often to iterate icons
                },
                cmake_virtual_text_support = false,
            }

            local function is_cmake_tools_running()
                local job = require("cmake-tools.utils").get_executor(require("cmake-tools.utils").executor.name).job
                return not job or job.is_shutdown
            end

            local _terminal = require "cmake-tools.terminal"
            local _quickfix = require "cmake-tools.quickfix"
            -- local osys = require'cmake-tools.osys'
            local notification = require "cmake-tools.notification"

            local function shlex_quote(s)
                if s == "" then return [['']] end
                if s:find [["]] and s:find [[\]] then
                    s = s:gsub([[\]], [[\\]])
                    s = s:gsub([["]], [[\"]])
                end
                if s:find [["]] then return "'" .. s .. "'" end
                return '"' .. s .. '"'
            end
            local notification_blacklist = {
                ["Exited with code 0"] = true,
                ["cmake"] = true,
            }
            local old_notification_notify = notification.notify
            function notification.notify(msg, lvl, opts)
                if msg ~= nil and not notification_blacklist[msg] then
                    return old_notification_notify(msg, lvl, opts)
                end
            end

            function _quickfix.has_active_job(opts)
                if not _quickfix.job or _quickfix.job.is_shutdown then return false end
                local log = require "cmake-tools.log"
                log.info "Stop running CMake job..."
                _quickfix.stop()
                -- local log = require("cmake-tools.log")
                -- log.error(
                --   "A CMake task is already running: "
                --     .. _quickfix.job.command
                --     .. " Stop it before trying to run a new CMake task."
                -- )
                return true
            end

            -- vim.cmd [[
            -- " avoid terminal hanging
            -- augroup auto_close_term
            -- autocmd!
            -- autocmd TermClose * execute 'bdelete! ' . expand('<abuf>')
            -- augroup END
            -- ]]
        end,
    },
    -- {
    --   "ranjithshegde/ccls.nvim",
    --   config = function() require("ccls").setup { lsp = { use_defaults = true } } end,
    -- },
    {
        "catppuccin/nvim",
        -- colorscheme catppuccin " catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
        -- config = function() vim.cmd "colorscheme catppuccin-frappe" end,
    },
    {
        "neanias/everforest-nvim",
        config = function()
            vim.g.everforest_background = "hard" -- 选项: 'hard', 'medium', 'soft'
            vim.g.everforest_better_performance = 1 -- 启用更好的性能
            vim.g.everforest_disable_italic_comment = 0 -- 启用斜体注释
            vim.g.everforest_transparent_background = 1 -- 启用透明背景
            vim.cmd "colorscheme everforest"
        end,
    },
    {
        "sainnhe/sonokai",
        -- config = function()
        --     vim.g.sonokai_style = "default" -- or 'atlantis', 'andromeda', 'shusia', 'maia', 'espresso'
        --     vim.g.sonokai_enable_italic = 1
        --     vim.g.sonokai_disable_italic_comment = 0
        --     vim.g.sonokai_transparent_background = 1 -- 启用透明背景
        --     vim.cmd "colorscheme sonokai"
        -- end,
    },

    {
        "ellisonleao/gruvbox.nvim",
        -- config = function()
        --   vim.g.gruvbox_style = "default" -- or 'atlantis', 'andromeda', 'shusia', 'maia', 'espresso'
        --   vim.g.gruvbox_enable_italic = 1
        --   vim.g.gruvbox_disable_italic_comment = 0
        --   vim.g.gruvbox_transparent_background = 1 -- 启用透明背景
        --   vim.cmd "colorscheme gruvbox"
        -- end,
    },
    {
        "github/copilot.vim",
        config = function()
            vim.g.copilot_no_tab_map = true
            vim.api.nvim_set_keymap("i", "<C-l>", 'copilot#Accept("<CR>")', {
                expr = true,
                silent = true,
                noremap = true,
            })
        end,
    },
    {
        "vim-airline/vim-airline",
        config = function()
            -- 确保 airline 配置在插件加载后设置
            vim.g["airline#extensions#tabline#enabled"] = 1
            vim.g["airline#extensions#tabline#buffer_nr_show"] = 1
            vim.g.airline_extensions_tabline_formatter = "default"
            vim.g.airline_section_y = 'BN: %{bufnr("%")}'
        end,
    },
    {
        "vim-airline/vim-airline-themes",
        config = function()
            -- 在主题插件加载后设置主题
            vim.defer_fn(function()
                vim.g.airline_theme = "violet"
                if vim.fn.exists ":AirlineRefresh" > 0 then vim.cmd "AirlineRefresh" end
            end, 100)
        end,
    },
    { "tpope/vim-fugitive" },
    { "MunifTanjim/nui.nvim" },
    {
        "VonHeikemen/fine-cmdline.nvim",
        config = function()
            require("fine-cmdline").setup {
                cmdline = {
                    enable_keymaps = true,
                    smart_history = true,
                    prompt = ": ",
                },
                popup = {
                    position = {
                        row = "10%",
                        col = "50%",
                    },
                    size = {
                        width = "60%",
                    },
                    border = {
                        style = "rounded",
                    },
                    win_options = {
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                    },
                },
                hooks = {
                    before_mount = function(input)
                        -- code
                    end,
                    after_mount = function(input)
                        -- code
                    end,
                    set_keymaps = function(imap, feedkeys)
                        -- code
                    end,
                },
            }
        end,
    },
    {
        "xiyaowong/transparent.nvim",
        config = function()
            require("transparent").setup {
                -- Optional, you don't have to run setup.
                groups = { -- table: default groups
                    "Normal",
                    "NormalNC",
                    "Comment",
                    "Constant",
                    "Special",
                    "Identifier",
                    "Statement",
                    "PreProc",
                    "Type",
                    "Underlined",
                    "Todo",
                    "String",
                    "Function",
                    "Conditional",
                    "Repeat",
                    "Operator",
                    "Structure",
                    "LineNr",
                    "NonText",
                    "SignColumn",
                    "CursorLine",
                    "CursorLineNr",
                    "StatusLine",
                    "StatusLineNC",
                    "EndOfBuffer",
                },
                extra_groups = {
                    "NeoTreeNormal",
                    "NeoTreeNormalNC",
                    "NvimTreeNormal",
                    "NvimTreeNormalNC",
                    "BufferLineTabClose",
                    "BufferlineBufferSelected",
                    "BufferLineFill",
                    "BufferLineBackground",
                    "BufferLineSeparator",
                    "BufferLineIndicatorSelected",
                    "FloatBorder",
                    "NormalFloat",
                    "FloatTitle",
                    "TelescopeNormal",
                    "TelescopeBorder",
                    "TelescopePromptNormal",
                    "TelescopePromptBorder",
                    "TelescopeResultsNormal",
                    "TelescopeResultsBorder",
                    "TelescopePreviewNormal",
                    "TelescopePreviewBorder",
                }, -- and this was super important as well
                exclude_groups = {}, -- table: groups you don't want to clear
            }

            -- 自动启用透明效果
            vim.defer_fn(function()
                require("transparent").clear_prefix "BufferLine"
                require("transparent").clear_prefix "lualine"
            end, 100)
        end,
    },
    {
        -- The task runner we use
        "stevearc/overseer.nvim",
        cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
        opts = {
            task_list = {
                direction = "bottom",
                min_height = 25,
                max_height = 25,
                default_detail = 1,
            },
        },
    },
    -- You can disable default plugins as follows:
    {
        "max397574/better-escape.nvim",
        enabled = false,
    },
    -- disable guess-indent to avoid it overwriting our indent settings
    -- {
    --     "NMAC427/guess-indent.nvim",
    --     enabled = false,
    -- },
    -- You can also easily customize additional setup of plugins that is outside of the plugin's setup call
    {
        "L3MON4D3/LuaSnip",
        config = function(plugin, opts)
            require "astronvim.plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
            -- add more custom luasnip configuration such as filetype extend or custom snippets
            local luasnip = require "luasnip"
            luasnip.filetype_extend("javascript", { "javascriptreact" })
        end,
    },
    {
        "windwp/nvim-autopairs",
        config = function(plugin, opts)
            require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
            -- add more custom autopairs configuration such as custom rules
            local npairs = require "nvim-autopairs"
            local Rule = require "nvim-autopairs.rule"
            local cond = require "nvim-autopairs.conds"
            npairs.add_rules(
                {
                    Rule("$", "$", { "tex", "latex" })
                        :with_pair(cond.not_after_regex "%%")
                        :with_pair( -- don't add a pair if the next character is %
                            -- don't add a pair if  the previous character is xxx
                            cond.not_before_regex("xxx", 3)
                        )
                        :with_move(cond.none())
                        :with_del(cond.not_after_regex "xx")
                        :with_cr(cond.none()), -- don't move right when repeat character
                    -- don't delete if the next character is xx
                    -- disable adding a newline when you press <cr>
                }, -- disable for .vim files, but it work for another filetypes
                Rule("a", "a", "-vim")
            )
        end,
    },
    -- Rust development: rust-tools + inlay hints (Neovim 0.10+ builtin or fallback)
    {
        "simrat39/rust-tools.nvim",
        ft = { "rust" },
        config = function()
            local ok, rust_tools = pcall(require, "rust-tools")
            if not ok then return end
            local lspconfig = require "lspconfig"

            local server_opts = {
                on_attach = function(client, bufnr)
                    -- Enable inlay hints: prefer built-in (nvim 0.10+), otherwise try lsp-inlayhints.nvim
                    if vim.lsp.inlay_hint then
                        pcall(vim.lsp.inlay_hint, bufnr, true)
                    else
                        local ok2, inlay = pcall(require, "lsp-inlayhints")
                        if ok2 and inlay.on_attach then pcall(inlay.on_attach, client, bufnr) end
                    end

                    -- Reduce noisy inline warnings: show virtual_text only for errors, keep signs/underline for warnings
                    -- This is global (Neovim diagnostic API); adjust if you want per-project behavior.
                    pcall(vim.diagnostic.config, {
                        virtual_text = { severity = { min = vim.diagnostic.severity.ERROR } },
                        signs = true,
                        underline = true,
                        update_in_insert = false,
                    })

                    -- example keymap for rust-tools
                    local opts = { noremap = true, silent = true }
                    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rh", "<cmd>RustHoverActions<CR>", opts)
                    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rc", "<cmd>RustCodeAction<CR>", opts)
                end,
                settings = {
                    ["rust-analyzer"] = {
                        cargo = { allFeatures = true },
                        -- `checkOnSave` can be a boolean in some rust-analyzer versions. Set to true to avoid
                        -- "invalid type: map" errors on older servers. If you want clippy diagnostics,
                        -- run `cargo clippy` manually or configure it via your toolchain/mason-managed RA.
                        checkOnSave = true,
                        -- Disable a few rust-analyzer diagnostics that are commonly noisy; add/remove as needed.
                        diagnostics = {
                            disabled = { "unresolved-proc-macro", "inactive-code" },
                        },
                        inlayHints = {
                            typeHints = true,
                            parameterHints = true,
                            chainingHints = true,
                            closureReturnTypeHints = true,
                            renderColons = true,
                        },
                    },
                },
            }

            rust_tools.setup {
                server = server_opts,
                tools = {
                    inlay_hints = {
                        auto = true,
                        show_parameter_hints = true,
                        parameter_hints_prefix = "<- ",
                        other_hints_prefix = "=> ",
                    },
                },
            }
        end,
    },
    {
        -- Fallback for Neovim <0.10: community inlay hints plugin
        "lvimuser/lsp-inlayhints.nvim",
        event = "LspAttach",
        config = function()
            local ok, inlay = pcall(require, "lsp-inlayhints")
            if not ok then return end
            inlay.setup()
        end,
    },
    {
        "nvimdev/lspsaga.nvim",
        event = "LspAttach",
        dependencies = { "nvim-tree/nvim-web-devicons", "nvim-treesitter/nvim-treesitter" },
        config = function()
            local ok, saga = pcall(require, "lspsaga")
            if not ok then return end
            saga.setup {
                ui = {
                    border = "rounded",
                    winblend = 0,
                },
                preview = {
                    lines_above = 0,
                    lines_below = 10,
                },
                lightbulb = {
                    enable = true,
                    sign = false, -- disable signcolumn icon to avoid overlapping LSP signs
                    virtual_text = true, -- use virtual text as alternative indicator
                    enable_in_insert = false,
                },
                symbol_in_winbar = { enable = false },
                scroll_preview = { scroll_down = "<C-f>", scroll_up = "<C-d>" },
            }

            -- useful keymaps for lspsaga features
            local map = vim.keymap.set
            map("n", "gh", "<cmd>Lspsaga lsp_finder<CR>", { silent = true }) -- find references/definitions
            map("n", "gr", "<cmd>Lspsaga rename<CR>", { silent = true })
            map("n", "ga", "<cmd>Lspsaga code_action<CR>", { silent = true })
            -- map("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true })
            -- ensure no global K mapping remains from lspsaga (remove if present)
            pcall(vim.keymap.del, "n", "K")
            -- Also remove any buffer-local 'K' mapping created by LSP or other plugins when a server attaches.
            -- This catches mappings that are set with the {buffer=bufnr} option which vim.keymap.del
            -- without a buffer cannot remove.
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args) pcall(vim.keymap.del, "n", "K", { buffer = args.buf }) end,
            })
            -- As a final safety, set a global no-op for 'K' so it doesn't fall back to any default behavior.
            -- Buffer-local mappings will still take precedence, but the autocmd above removes those on attach.
            pcall(vim.keymap.set, "n", "K", "<nop>", { silent = true })
            map("n", "<leader>sl", "<cmd>Lspsaga show_line_diagnostics<CR>", { silent = true })
            map("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { silent = true })
            map("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", { silent = true })
        end,
    },
}

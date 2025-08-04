-- You can also add or configure plugins by creating files in this `plugins/` folder
-- Here are some examples:

---@type LazySpec
return {
  plugins = {
    init = {
      ["Darazaki/indent-o-matic"] = {disable = true},
      ["lukas-reineke/indent-blankline.nvim"] = {disable = true}
    }
  },
  -- == Examples of Adding Plugins ==

  "andweeb/presence.nvim",
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function()
      require("lsp_signature").setup()
    end
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
        "  ██████  ██████   █████     ██████    ███████"
      }
      return opts
    end
  },
  {
    "Civitasv/cmake-tools.nvim",
    config = function()
      require("cmake-tools").setup {
        cmake_command = "cmake", -- this is used to specify cmake command path
        cmake_regenerate_on_save = false, -- auto generate when save CMakeLists.txt
        cmake_generate_options = {"-DCMAKE_EXPORT_COMPILE_COMMANDS=1"}, -- this will be passed when invoke `CMakeGenerate`
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
          short = {show = true}, -- whether to show short message
          long = {show = true, max_length = 80} -- whether to show long message
        },
        cmake_dap_configuration = {
          -- debug settings for cmake
          name = "cpp",
          type = "codelldb",
          request = "launch",
          stopOnEntry = false,
          runInTerminal = true,
          console = "integratedTerminal"
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
              auto_close_when_success = true -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
            },
            toggleterm = {
              direction = "horizontal", -- 'vertical' | 'horizontal' | 'tab' | 'float'
              close_on_exit = true, -- whether close the terminal when exit
              auto_scroll = true -- whether auto scroll to the bottom
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
              do_not_add_newline = true -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
            }
          }
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
              auto_close_when_success = true -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
            },
            toggleterm = {
              -- direction = "horizontal", -- 'vertical' | 'horizontal' | 'tab' | 'float'
              direction = "tab", -- 'vertical' | 'horizontal' | 'tab' | 'float'
              close_on_exit = false, -- whether close the terminal when exit
              auto_scroll = true, -- whether auto scroll to the bottom
              singleton = true -- single instance, autocloses the opened one, if present
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
              do_not_add_newline = false -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
            }
          }
        },
        cmake_notifications = {
          runner = {enabled = false},
          executor = {enabled = false},
          spinner = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}, -- icons used for progress display
          refresh_rate_ms = 100 -- how often to iterate icons
        },
        cmake_virtual_text_support = false
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
        if s == "" then
          return [['']]
        end
        if s:find [["]] and s:find [[\]] then
          s = s:gsub([[\]], [[\\]])
          s = s:gsub([["]], [[\"]])
        end
        if s:find [["]] then
          return "'" .. s .. "'"
        end
        return '"' .. s .. '"'
      end
      local notification_blacklist = {
        ["Exited with code 0"] = true,
        ["cmake"] = true
      }
      local old_notification_notify = notification.notify
      function notification.notify(msg, lvl, opts)
        if msg ~= nil and not notification_blacklist[msg] then
          return old_notification_notify(msg, lvl, opts)
        end
      end

      function _quickfix.has_active_job(opts)
        if not _quickfix.job or _quickfix.job.is_shutdown then
          return false
        end
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
    end
  },
  -- {
  --   "ranjithshegde/ccls.nvim",
  --   config = function() require("ccls").setup { lsp = { use_defaults = true } } end,
  -- },
  {
    "glepnir/zephyr-nvim"
    -- config = function()
    --   require "zephyr"
    --   vim.cmd "colorscheme zephyr"
    -- end,
  },
  {
    "sainnhe/sonokai",
    config = function()
      vim.g.sonokai_style = "default" -- or 'atlantis', 'andromeda', 'shusia', 'maia', 'espresso'
      vim.g.sonokai_enable_italic = 1
      vim.g.sonokai_disable_italic_comment = 0
      vim.g.sonokai_transparent_background = 1 -- 启用透明背景
      vim.cmd "colorscheme sonokai"

      -- 设置对应的 airline 主题
      vim.defer_fn(
        function()
          if vim.fn.exists(":AirlineTheme") > 0 then
            pcall(
              function()
                vim.cmd("AirlineTheme sonokai")
              end
            )
          end
        end,
        100
      )
    end
  },
  {
    "ellisonleao/gruvbox.nvim"
    -- config = function()
    --   require("gruvbox").setup()
    --   vim.cmd "colorscheme gruvbox"
    -- end
  },
  {
    "vim-airline/vim-airline",
    config = function()
      -- 确保 airline 配置在插件加载后设置
      vim.g.airline_powerline_fonts = 1 -- 如果你有 powerline 字体
      vim.g["airline#extensions#tabline#enabled"] = 1
      vim.g["airline#extensions#tabline#buffer_nr_show"] = 1
    end
  },
  {
    "vim-airline/vim-airline-themes",
    config = function()
      -- 在主题插件加载后设置主题
      vim.defer_fn(function()
        vim.g.airline_theme = "atomic"
        if vim.fn.exists(':AirlineRefresh') > 0 then
          vim.cmd("AirlineRefresh")
        end
      end, 100)
    end
  },
  {
    "tpope/vim-fugitive"
  },
  {
    "MunifTanjim/nui.nvim"
  },
  {
    "VonHeikemen/fine-cmdline.nvim",
    config = function()
      require("fine-cmdline").setup {
        cmdline = {
          enable_keymaps = true,
          smart_history = true,
          prompt = ": "
        },
        popup = {
          position = {
            row = "10%",
            col = "50%"
          },
          size = {
            width = "60%"
          },
          border = {
            style = "rounded"
          },
          win_options = {
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder"
          }
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
          end
        }
      }
    end
  },
  {
    "xiyaowong/transparent.nvim",
    config = function()
      require("transparent").setup {
        -- Optional, you don't have to run setup.
        groups = {
          -- table: default groups
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
          "EndOfBuffer"
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
          "TelescopePreviewBorder"
        }, -- and this was super important as well
        exclude_groups = {} -- table: groups you don't want to clear
      }

      -- 自动启用透明效果
      vim.defer_fn(
        function()
          require("transparent").clear_prefix("BufferLine")
          require("transparent").clear_prefix("lualine")
        end,
        100
      )
    end
  },
  {
    -- This plugin
    "Zeioth/compiler.nvim",
    cmd = {"CompilerOpen", "CompilerToggleResults", "CompilerRedo"},
    dependencies = {"stevearc/overseer.nvim", "nvim-telescope/telescope.nvim"},
    opts = {}
  },
  {
    -- The task runner we use
    "stevearc/overseer.nvim",
    cmd = {"CompilerOpen", "CompilerToggleResults", "CompilerRedo"},
    opts = {
      task_list = {
        direction = "bottom",
        min_height = 25,
        max_height = 25,
        default_detail = 1
      }
    }
  },
  -- You can disable default plugins as follows:
  {"max397574/better-escape.nvim", enabled = false},
  -- You can also easily customize additional setup of plugins that is outside of the plugin's setup call
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom luasnip configuration such as filetype extend or custom snippets
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", {"javascriptreact"})
    end
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
          Rule("$", "$", {"tex", "latex"}):with_pair(cond.not_after_regex "%%"):with_pair(
            -- don't add a pair if the next character is %
            -- don't add a pair if  the previous character is xxx
            cond.not_before_regex("xxx", 3)
          ):with_move(cond.none()):with_del(cond.not_after_regex "xx"):with_cr(cond.none())
          -- don't move right when repeat character
          -- don't delete if the next character is xx
          -- disable adding a newline when you press <cr>
        },
        -- disable for .vim files, but it work for another filetypes
        Rule("a", "a", "-vim")
      )
    end
  }
}

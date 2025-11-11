-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Set up custom filetypes
vim.filetype.add {
    extension = {
        foo = "fooscript",
    },
    filename = {
        ["Foofile"] = "fooscript",
    },
    pattern = {
        ["~/%.config/foo/.*"] = "fooscript",
    },
}

-- 控制是否自动在 CursorHold 时弹出预览（默认关闭）
vim.g.macro_preview_auto = false
-- 可配置的边框颜色（可在 init.lua 或其他地方通过 vim.g 设置）
vim.g.macro_float_border_color = vim.g.macro_float_border_color or "#ff77b1"

-- 自定义悬浮窗口高亮组（不影响代码高亮）
vim.api.nvim_set_hl(0, "MacroFloatNormal", {
    bg = "NONE", -- 透明背景
    fg = "#e2e8f0", -- 浅灰色文字
    blend = 10, -- 透明度
})

vim.api.nvim_set_hl(0, "MacroFloatBorder", {
    -- bg = "#2d3748", -- 与背景一致
    bg = "NONE",
    fg = vim.g.macro_float_border_color, -- 可配置的边框颜色
    bold = true,
})

vim.api.nvim_set_hl(0, "MacroFloatTitle", {
    bg = "NONE", -- 透明标题背景
    fg = "#1a202c", -- 深色文字
    bold = true,
})

vim.api.nvim_set_hl(0, "MacroCodeBlock", {
    -- bg = "#1a202c", -- 更深的背景用于代码块
    bg = "NONE",
    fg = "#fbb6ce", -- 粉色代码文字
    italic = true,
})

vim.api.nvim_set_hl(0, "MacroKeyword", {
    fg = "#9dd368", -- 绿色关键字
    bold = true,
})

vim.api.nvim_set_hl(0, "MacroType", {
    fg = "#90cdf4", -- 蓝色类型
    italic = true,
})

vim.api.nvim_set_hl(0, "MacroLabel", {
    fg = "#ff77b1", -- 粉色标签（Type:, Offset:, Size: 等）
    bold = true,
})

vim.api.nvim_set_hl(0, "MacroQuote", {
    fg = "#fa2891", -- 引用符号 (>)
    bold = true,
})

-- 设置markdown中粗体文字的颜色为青色（仅在悬浮窗口中）
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        if vim.api.nvim_win_get_config(0).relative ~= "" then
            -- 仅在浮动窗口中应用
            vim.api.nvim_set_hl(0, "@markup.strong.markdown_inline", {
                fg = "#ff77b1",
                bold = true,
            })

            -- 设置markdown引用符号的颜色
            vim.api.nvim_set_hl(0, "@markup.quote.markdown", {
                fg = "#67f151",
                bold = true,
            })

            -- 设置代码块中的引用符号颜色
            vim.api.nvim_set_hl(0, "@markup.raw.markdown_inline", {
                fg = "#2dded5",
                bold = true,
            })
        end
    end,
})

-- 宏展开悬浮预览功能
local function show_macro_expansion()
    -- 定义带颜色的引用符号
    local green_quote = "**`>`**" -- 使用markdown格式来突出显示

    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor_pos[1] - 1, cursor_pos[2]

    -- 检查文件类型，支持多种编程语言
    local filetype = vim.bo[bufnr].filetype
    local allowed_filetypes = {
        "c",
        "cpp",
        "cc",
        "cxx",
        "h",
        "hpp",
        "hxx",
        "cuda",
        "cu", -- C/C++/CUDA
        "python",
        "py", -- Python
        "go", -- Go
        "rust",
        "rs", -- Rust
        "lua", -- Lua
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "ts",
        "tsx",
        "jsx",
    }
    local is_allowed = false
    for _, ft in ipairs(allowed_filetypes) do
        if filetype == ft then
            is_allowed = true
            break
        end
    end
    if not is_allowed then return end

    -- 获取光标下的单词
    local word = vim.fn.expand "<cword>"
    if word == "" or string.len(word) < 2 then return end

    -- 防止重复触发
    if vim.b.last_macro_word == word and vim.b.last_macro_time and (vim.loop.now() - vim.b.last_macro_time) < 1000 then
        return
    end

    vim.b.last_macro_word = word
    vim.b.last_macro_time = vim.loop.now()

    -- 首先尝试本地搜索宏定义（更快）
    local found_local = show_macro_definition(word, bufnr)

    -- 如果本地没找到，再尝试 LSP
    if not found_local then
        local clients = vim.lsp.get_clients { bufnr = bufnr }
        if #clients == 0 then return end

        local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding)
        vim.lsp.buf_request(bufnr, "textDocument/hover", params, function(err, result, ctx, config)
            if err or not result or not result.contents then return end

            -- 检查 hover 结果中是否包含宏信息
            local contents = result.contents
            local content_str = ""

            if type(contents) == "string" then
                content_str = contents
            elseif type(contents) == "table" then
                if contents.value then
                    content_str = contents.value
                elseif contents[1] and contents[1].value then
                    content_str = contents[1].value
                end
            end

            -- 检查是否包含宏相关信息
            if
                content_str ~= ""
                and (
                    string.find(content_str, "#define", 1, true)
                    or string.find(content_str, "macro", 1, true)
                    or string.find(content_str, "MACRO", 1, true)
                    or string.find(content_str, word, 1, true)
                )
            then
                -- 选择代码块语言以便语法高亮（基于文件类型）
                local code_lang = "c"
                if filetype:match("typescript") or filetype == "ts" or filetype == "tsx" then
                    code_lang = "ts"
                elseif filetype:match("javascript") or filetype == "js" or filetype == "jsx" or filetype == "javascriptreact" then
                    code_lang = "js"
                elseif filetype == "cpp" or filetype == "c++" then
                    code_lang = "cpp"
                end

                -- 格式化内容，使其更美观
                local formatted_content = {}

                -- 添加标题
                table.insert(formatted_content, "🔍 " .. word .. " - Symbol Information")
                table.insert(formatted_content, "")

                -- 处理多行内容，添加颜色高亮
                for line in content_str:gmatch "[^\r\n]+" do
                    -- 清理markdown标题符号
                    line = string.gsub(line, "^###%s*", "")
                    line = string.gsub(line, "^##%s*", "")
                    line = string.gsub(line, "^#%s*", "")

                    -- 处理带标签的行 (Type:, Offset:, Size: 等，但排除 C++ 访问修饰符)
                    local label_pattern = "^(%w+):%s*(.*)$"
                    local label, value = string.match(line, label_pattern)

                    -- 排除 C++ 访问修饰符和其他不应该被格式化为标签的内容
                    local excluded_labels = {
                        "public",
                        "private",
                        "protected",
                        "class",
                        "struct",
                        "namespace",
                    }
                    local is_excluded = false
                    if label then
                        for _, excluded in ipairs(excluded_labels) do
                            if string.lower(label) == excluded then
                                is_excluded = true
                                break
                            end
                        end
                    end

                    if not macro_info_inserted then macro_info_inserted = false end
                    if label and value and not is_excluded then
                        local formatted_line = string.format("%s: %s", label, value)
                        table.insert(formatted_content, formatted_line)
                    elseif string.find(line, "#define", 1, true) then
                        table.insert(formatted_content, "📌 Macro Definition:")
                        table.insert(formatted_content, "```" .. code_lang)
                        table.insert(formatted_content, line)
                        table.insert(formatted_content, "```")
                    elseif
                        (string.find(line, "macro", 1, true) or string.find(line, "MACRO", 1, true))
                        and not macro_info_inserted
                    then
                        table.insert(formatted_content, "🔧 Macro Info:")
                        macro_info_inserted = true
                        table.insert(formatted_content, "```" .. code_lang)
                        table.insert(formatted_content, line)
                        table.insert(formatted_content, "```")
                    elseif
                        (string.find(line, "macro", 1, true) or string.find(line, "MACRO", 1, true))
                        and macro_info_inserted
                    then
                        table.insert(formatted_content, "```" .. code_lang)
                        table.insert(formatted_content, line)
                        table.insert(formatted_content, "```")
                    elseif string.find(line, "expand", 1, true) or string.find(line, "EXPAND", 1, true) then
                        table.insert(formatted_content, "⚡ Expansion:")
                        table.insert(formatted_content, "```diff")
                        table.insert(formatted_content, "+ " .. line)
                        table.insert(formatted_content, "```")
                    else
                        table.insert(formatted_content, line)
                    end
                end

                table.insert(formatted_content, "")
                table.insert(formatted_content, "---")
                table.insert(formatted_content, "💡 Press `q` or move cursor to close")

                -- 显示宏展开信息，使用多色高亮
                vim.lsp.util.open_floating_preview(formatted_content, "markdown", {
                    border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                    focusable = true,
                    close_events = { "CursorMoved", "BufHidden", "InsertCharPre" },
                    -- title = " 🔮 Symbol & Macro Preview ",
                    title_pos = "center",
                    max_width = 100,
                    max_height = 25,
                    wrap = true,
                    style = "minimal",
                    -- make the floating window blend with the background more so
                    -- it appears transparent even if colorschemes set defaults
                    -- (increase this value if you want stronger transparency)
                    winblend = 10,
                    winhighlight = "Normal:MacroFloatNormal,NormalFloat:MacroFloatNormal,FloatBorder:MacroFloatBorder,FloatTitle:MacroFloatTitle,@markup.strong.markdown_inline:MacroLabel,@markup.quote.markdown:MacroQuote,@markup.raw.markdown_inline:MacroQuote",
                })
            end
        end)
    end
end

-- 查找宏定义的辅助函数
function show_macro_definition(word, bufnr)
    -- 定义带颜色的引用符号
    local green_quote = "**`>`**" -- 使用markdown格式来突出显示

    -- 在当前缓冲区和包含文件中搜索宏/常量定义
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local macro_definition = nil
    local filetype = vim.bo[bufnr].filetype

    for i, line in ipairs(lines) do
        local match = nil
        local definition_type = ""

        -- 根据文件类型查找不同的定义模式
        if
            filetype == "c"
            or filetype == "cpp"
            or filetype == "cc"
            or filetype == "cxx"
            or filetype == "h"
            or filetype == "hpp"
            or filetype == "hxx"
            or filetype == "cuda"
            or filetype == "cu"
        then
            -- C/C++/CUDA: #define 宏定义
            local define_pattern = "#define%s+" .. word .. "%s*(.*)$"
            match = string.match(line, define_pattern)
            definition_type = "C/C++ Macro"
        elseif filetype == "python" or filetype == "py" then
            -- Python: 常量定义 (大写变量)
            local const_pattern = "^%s*" .. word .. "%s*=%s*(.*)$"
            if word:match "^[A-Z_][A-Z0-9_]*$" then -- 只匹配大写常量
                match = string.match(line, const_pattern)
                definition_type = "Python Constant"
            end
        elseif filetype == "go" then
            -- Go: const 常量定义
            local const_pattern = "const%s+" .. word .. "%s*=%s*(.*)$"
            match = string.match(line, const_pattern)
            definition_type = "Go Constant"
        elseif filetype == "rust" or filetype == "rs" then
            -- Rust: const 常量定义
            local const_pattern = "const%s+" .. word .. "%s*:%s*[^=]*=%s*(.*)$"
            match = string.match(line, const_pattern)
            definition_type = "Rust Constant"
        elseif filetype == "kotlin" or filetype == "kt" or filetype == "kts" then
            -- Kotlin: const val 或 val 常量定义
            local const_pattern1 = "const%s+val%s+" .. word .. "%s*=%s*(.*)$"
            local const_pattern2 = "val%s+" .. word .. "%s*=%s*(.*)$"
            match = string.match(line, const_pattern1) or string.match(line, const_pattern2)
            definition_type = "Kotlin Constant"
        elseif filetype == "lua" then
            -- Lua: 局部或全局常量定义
            local const_pattern1 = "local%s+" .. word .. "%s*=%s*(.*)$"
            local const_pattern2 = "^%s*" .. word .. "%s*=%s*(.*)$"
            match = string.match(line, const_pattern1) or string.match(line, const_pattern2)
            definition_type = "Lua Variable"
        elseif filetype == "javascript"
            or filetype == "javascriptreact"
            or filetype == "typescript"
            or filetype == "typescriptreact"
            or filetype == "ts"
            or filetype == "tsx"
            or filetype == "jsx"
        then
            -- JavaScript / TypeScript: const/let/var, export, function, class, type, interface
            local patterns = {
                "^%s*export%s+const%s+" .. word .. "%s*=%s*(.*)$",
                "^%s*const%s+" .. word .. "%s*=%s*(.*)$",
                "^%s*let%s+" .. word .. "%s*=%s*(.*)$",
                "^%s*var%s+" .. word .. "%s*=%s*(.*)$",
                "^%s*export%s+function%s+" .. word .. "%s*%((.*)%)",
                "^%s*function%s+" .. word .. "%s*%((.*)%)",
                "^%s*class%s+" .. word .. "%s*" ,
                "^%s*type%s+" .. word .. "%s*=%s*(.*)$",
                "^%s*interface%s+" .. word .. "%s*{",
            }
            for _, pat in ipairs(patterns) do
                local m = string.match(line, pat)
                if m then
                    match = m
                    break
                end
            end
            definition_type = "JS/TS Symbol"
        end

        if match then
            macro_definition = {
                line_num = i,
                definition = line,
                expansion = match,
                type = definition_type,
            }
            break
        end
    end

    if macro_definition then
        -- choose code fence language for better syntax highlighting
        local def_lang = "c"
        if filetype:match("typescript") or filetype == "ts" or filetype == "tsx" then
            def_lang = "ts"
        elseif filetype:match("javascript") or filetype == "js" or filetype == "jsx" or filetype == "javascriptreact" then
            def_lang = "js"
        end

        local content = {
            "# 🔍 " .. word .. " - " .. macro_definition.type,
            "",
            "**📍 Location:** `Line " .. macro_definition.line_num .. "`",
            "",
            "**📝 Definition:**",
        }

        -- 添加定义，用代码块包围，并标记函数参数和返回值
        if
            string.find(macro_definition.definition, "(", 1, true)
            and string.find(macro_definition.definition, ")", 1, true)
        then
            -- 如果是函数宏，特别标记
            table.insert(content, "```" .. def_lang)
            table.insert(content, macro_definition.definition)
            table.insert(content, "```")
            table.insert(content, "🔵 **Function-like Definition**")
        else
            -- 普通宏定义
            table.insert(content, "```" .. def_lang)
            table.insert(content, macro_definition.definition)
            table.insert(content, "```")
            table.insert(content, "📌 **Constant Definition**")
        end
        table.insert(content, "")

        -- 如果有展开内容，显示它，并分析是否包含函数调用
        if macro_definition.expansion and macro_definition.expansion ~= "" then
            table.insert(content, "**🔧 Expansion Value:**")

            -- 检查展开内容是否包含函数调用
            if
                string.find(macro_definition.expansion, "(", 1, true)
                and string.find(macro_definition.expansion, ")", 1, true)
            then
                table.insert(content, "```" .. def_lang)
                table.insert(content, macro_definition.expansion)
                table.insert(content, "```")
                table.insert(content, "🔄 **Function Call/Expression**")
            else
                table.insert(content, "```" .. def_lang)
                table.insert(content, macro_definition.expansion)
                table.insert(content, "```")
                table.insert(content, "💾 **Constant Value**")
            end
            table.insert(content, "")
        end

        table.insert(content, "---")
        table.insert(content, green_quote .. " 💡 Press `q` or move cursor to close")

        -- 使用彩色高亮显示本地宏定义
        vim.lsp.util.open_floating_preview(content, "markdown", {
            border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
            focusable = true,
            close_events = { "CursorMoved", "BufHidden", "InsertCharPre", "BufLeave" },
            title = " ⚡ " .. macro_definition.type .. " Preview ",
            title_pos = "center",
            max_width = 100,
            max_height = 20,
            wrap = true,
            style = "minimal",
            -- stronger blend so the inner background becomes visually transparent
            winblend = 40,
            winhighlight = "Normal:MacroFloatNormal,NormalFloat:MacroFloatNormal,FloatBorder:MacroFloatBorder,FloatTitle:MacroFloatTitle,@markup.strong.markdown_inline:MacroLabel,@markup.quote.markdown:MacroQuote,@markup.raw.markdown_inline:MacroQuote",
        })
        return true
    end
    return false
end

-- clangd 特定的宏展开功能
local function clangd_expand_macro()
    local bufnr = vim.api.nvim_get_current_buf()

    -- 检查文件类型
    local filetype = vim.bo[bufnr].filetype
    local allowed_filetypes = {
        "c",
        "cpp",
        "cc",
        "cxx",
        "h",
        "hpp",
        "hxx",
        "cuda",
        "cu", -- C/C++/CUDA
        "python",
        "py", -- Python
        "go", -- Go
        "rust",
        "rs", -- Rust
        "kotlin",
        "kt",
        "kts", -- Kotlin
        "lua", -- Lua
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "ts",
        "tsx",
        "jsx",
    }
    local is_allowed = false
    for _, ft in ipairs(allowed_filetypes) do
        if filetype == ft then
            is_allowed = true
            break
        end
    end
    if not is_allowed then return end

    -- 获取光标下的单词并过滤基本类型
    local word = vim.fn.expand "<cword>"
    if word == "" or string.len(word) < 2 then return end

    local clangd_client = require("lspconfig.util").get_active_client_by_name(bufnr, "clangd")

    if not clangd_client then
        show_macro_expansion() -- 回退到通用方法
        return
    end

    local params = vim.lsp.util.make_position_params(0, clangd_client.offset_encoding)
    clangd_client.request("textDocument/semanticTokens/range", {
        textDocument = params.textDocument,
        range = {
            start = params.position,
            ["end"] = params.position,
        },
    }, function(err, result)
        if err or not result then
            show_macro_expansion() -- 回退到通用方法
            return
        end
        -- 处理 clangd 的语义标记结果
        show_macro_expansion()
    end, bufnr)
end

-- 设置自动命令和快捷键
vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "c",
        "cpp",
        "cc",
        "cxx",
        "h",
        "hpp",
        "hxx",
        "cuda",
        "cu", -- C/C++/CUDA
        "python",
        "py", -- Python
        "go", -- Go
        "rust",
        "rs", -- Rust
        "kotlin",
        "kt",
        "kts", -- Kotlin
        "lua", -- Lua
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "ts",
        "tsx",
        "jsx",
    },
    callback = function()
        -- 为支持的编程语言设置宏/符号展开快捷键
        -- vim.keymap.set("n", "<leader>me", clangd_expand_macro, {
        vim.keymap.set("n", "L", clangd_expand_macro, {
            buffer = true,
            desc = "Expand macro under cursor",
        })

        -- 悬浮时自动显示宏信息 (可选)
        -- vim.keymap.set("n", "K", function()
        --   vim.lsp.buf.hover()
        --   vim.defer_fn(show_macro_expansion, 100)
        -- end, { buffer = true, desc = "Hover with macro expansion" })
    end,
})

-- 通用的宏展开快捷键
vim.keymap.set("n", "<leader>mx", show_macro_expansion, {
    desc = "Show macro expansion",
})

-- 设置更短的悬停时间
vim.opt.updatetime = 1200

-- CursorHold 事件自动显示宏信息
vim.api.nvim_create_autocmd("CursorHold", {
    pattern = { "*.c", "*.cpp", "*.h", "*.hpp", "*.cu", "*.cc", "*.cxx" },
    callback = function()
        if vim.g.macro_preview_auto == false then return end
        local word = vim.fn.expand "<cword>"
        -- 检查是否是可能的宏名称（大写字母开头或包含下划线的标识符）
        if
            word ~= ""
            and (
                string.match(word, "^[A-Z_][A-Z0-9_]*$") -- 全大写宏
                or string.match(word, "^[a-zA-Z_][a-zA-Z0-9_]*$")
            )
        then -- 普通标识符
            -- 延迟执行，避免频繁触发
            vim.defer_fn(function() show_macro_expansion() end, 200)
        end
    end,
})

-- 为所有文件类型启用悬浮预览（不仅仅是 C/C++）
vim.api.nvim_create_autocmd("CursorHold", {
    pattern = "*",
    callback = function()
        if vim.g.macro_preview_auto == false then return end
        local filetype = vim.bo.filetype
        -- 跳过特殊文件类型
        if filetype == "help" or filetype == "man" or filetype == "qf" then return end

        local word = vim.fn.expand "<cword>"
        if word ~= "" and string.len(word) > 2 then
            -- 对于非 C/C++ 文件，使用更宽松的条件
            vim.defer_fn(function() show_macro_expansion() end, 300)
        end
    end,
})

-- 强化透明效果设置
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        -- 确保背景透明
        vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", ctermbg = "NONE" })
    -- Reapply custom macro float highlights so colorschemes won't override them
    vim.api.nvim_set_hl(0, "MacroFloatNormal", { bg = "NONE", fg = "#e2e8f0" })
    vim.api.nvim_set_hl(0, "MacroFloatBorder", { bg = "NONE", fg = vim.g.macro_float_border_color or "#ff77b1", bold = true })
    vim.api.nvim_set_hl(0, "MacroFloatTitle", { bg = "NONE", fg = "#1a202c", bold = true })
    vim.api.nvim_set_hl(0, "MacroCodeBlock", { bg = "NONE", fg = "#fbb6ce", italic = true })
        vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE", ctermbg = "NONE" })

        -- 侧边栏透明
        vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "NONE", ctermbg = "NONE" })

        -- Telescope 透明
        vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = "NONE", ctermbg = "NONE" })
    end,
})

-- 立即应用透明设置
vim.defer_fn(function()
    vim.cmd "hi Normal guibg=NONE ctermbg=NONE"
    vim.cmd "hi NormalNC guibg=NONE ctermbg=NONE"
    vim.cmd "hi SignColumn guibg=NONE ctermbg=NONE"
    vim.cmd "hi StatusLine guibg=NONE ctermbg=NONE"
    vim.cmd "hi StatusLineNC guibg=NONE ctermbg=NONE"
    vim.cmd "hi LineNr guibg=NONE ctermbg=NONE"
    vim.cmd "hi CursorLineNr guibg=NONE ctermbg=NONE"
    vim.cmd "hi EndOfBuffer guibg=NONE ctermbg=NONE"
end, 100)

-- Ensure our floating preview highlights are re-applied after startup/plugins
-- Some plugins or late colorscheme changes may overwrite these groups; pressing
-- F8 previously ran code that set NormalFloat/FloatBorder, which is why the
-- preview became transparent only after that. To make transparency reliable
-- we reapply our highlights on VimEnter and a few delayed retries.
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local function apply_float_hls()
            vim.api.nvim_set_hl(0, "MacroFloatNormal", { bg = "NONE", fg = "#e2e8f0" })
            vim.api.nvim_set_hl(0, "MacroFloatBorder", { bg = "NONE", fg = vim.g.macro_float_border_color or "#ff77b1", bold = true })
            vim.api.nvim_set_hl(0, "MacroFloatTitle", { bg = "NONE", fg = "#1a202c", bold = true })
            vim.api.nvim_set_hl(0, "MacroCodeBlock", { bg = "NONE", fg = "#fbb6ce", italic = true })
            -- Also ensure the standard float groups are transparent
            vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", ctermbg = "NONE" })
            vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE", ctermbg = "NONE" })
        end

        -- immediate
        apply_float_hls()
        -- a couple of delayed retries to catch late plugin/theme overrides
        vim.defer_fn(apply_float_hls, 200)
        vim.defer_fn(apply_float_hls, 800)
    end,
})

vim.g.clang_format_style_options = {
    AccessModifierOffset = -4,
    AllowShortIfStatementsOnASingleLine = "true",
    AlwaysBreakTemplateDeclarations = "true",
    Standard = "C++23",
    BreakBeforeBraces = "Stroustrup",
}

-- Ensure buffers use 4-space indentation. Some plugins (guess-indent, formatters)
-- or LSP/on-save formatting can change buffer-local settings; enforce after
-- common events to make vim.opt options take effect per-buffer.
local function enforce_4_space_indent(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    -- Only set for normal file buffers (skip terminals, help, etc.)
    local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
    if buftype ~= "" then return end
    vim.bo[bufnr].expandtab = true
    vim.bo[bufnr].shiftwidth = 4
    vim.bo[bufnr].tabstop = 4
    vim.bo[bufnr].softtabstop = 4
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "FileType" }, {
    callback = function(args) enforce_4_space_indent(args.buf) end,
})

-- If an LSP attaches it may influence formatting; set after attach as well.
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args) enforce_4_space_indent(args.buf) end,
})

-- Some formatters run on save and may alter whitespace; re-apply after write.
vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function(args) enforce_4_space_indent(args.buf) end,
})

-- 导出模块接口，便于从其他地方调用自定义的预览函数
return {
    show_macro_expansion = show_macro_expansion,
    show_macro_definition = show_macro_definition,
    clangd_expand_macro = clangd_expand_macro,
}



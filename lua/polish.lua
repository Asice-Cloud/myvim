-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Set up custom filetypes
vim.filetype.add {
  extension = {
    foo = "fooscript"
  },
  filename = {
    ["Foofile"] = "fooscript"
  },
  pattern = {
    ["~/%.config/foo/.*"] = "fooscript"
  }
}

-- 宏展开悬浮预览功能
local function show_macro_expansion()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor_pos[1] - 1, cursor_pos[2]

  -- 获取光标下的单t
  local word = vim.fn.expand("<cword>")
  if word == "" or string.len(word) < 2 then
    return
  end

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
    local clients = vim.lsp.get_clients({bufnr = bufnr})
    if #clients == 0 then
      return
    end

    local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding)
    vim.lsp.buf_request(
      bufnr,
      "textDocument/hover",
      params,
      function(err, result, ctx, config)
        if err or not result or not result.contents then
          return
        end

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
          content_str ~= "" and
            (string.find(content_str, "#define", 1, true) or string.find(content_str, "macro", 1, true) or
              string.find(content_str, "MACRO", 1, true) or
              string.find(content_str, word, 1, true))
         then
          -- 格式化内容，使其更美观
          local formatted_content = {}

          -- 添加标题
          table.insert(formatted_content, "🔍 " .. word .. " - Symbol Information")
          table.insert(formatted_content, string.rep("─", 50))
          table.insert(formatted_content, "")

          -- 处理多行内容，添加颜色高亮
          for line in content_str:gmatch("[^\r\n]+") do
            -- 高亮 #define 行
            if string.find(line, "#define", 1, true) then
              table.insert(formatted_content, "```cpp")
              table.insert(formatted_content, "📌 " .. line)
              table.insert(formatted_content, "```")
            elseif string.find(line, "macro", 1, true) or string.find(line, "MACRO", 1, true) then
              table.insert(formatted_content, "```c")
              table.insert(formatted_content, "🔧 " .. line)
              table.insert(formatted_content, "```")
            elseif string.find(line, "expand", 1, true) or string.find(line, "EXPAND", 1, true) then
              table.insert(formatted_content, "```diff")
              table.insert(formatted_content, "+ ⚡ " .. line)
              table.insert(formatted_content, "```")
            else
              -- 普通行用引用格式
              table.insert(formatted_content, "> " .. line)
            end
          end

          table.insert(formatted_content, "")

          -- 显示宏展开信息，使用多色高亮
          vim.lsp.util.open_floating_preview(
            formatted_content,
            "markdown",
            {
              border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"},
              focusable = true,
              close_events = {"CursorMoved", "BufHidden", "InsertCharPre"},
              title = " Macro and Type Preview ",
              title_pos = "center",
              max_width = 100,
              max_height = 25,
              wrap = true,
              style = "minimal",
              winhighlight = "Normal:MacroFloatNormal,FloatBorder:MacroFloatBorder,FloatTitle:MacroFloatTitle"
            }
          )
        end
      end
    )
  end
end

-- 查找宏定义的辅助函数
function show_macro_definition(word, bufnr)
  -- 在当前缓冲区和包含文件中搜索宏定义
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local macro_definition = nil

  for i, line in ipairs(lines) do
    -- 查找 #define 宏定义
    local define_pattern = "#define%s+" .. word .. "%s*(.*)$"
    local match = string.match(line, define_pattern)
    if match then
      macro_definition = {
        line_num = i,
        definition = line,
        expansion = match
      }
      break
    end
  end

  if macro_definition then
    local content = {
      "# " .. word .. " - Macro Definition",
      "",
      "**📍 Location:** Line " .. macro_definition.line_num,
      "",
      "**📝 Definition:**"
    }

    -- 添加定义，用代码块包围，并标记函数参数和返回值
    if string.find(macro_definition.definition, "(", 1, true) and string.find(macro_definition.definition, ")", 1, true) then
      -- 如果是函数宏，特别标记
      table.insert(content, "```c")
      table.insert(content, macro_definition.definition .. " // 🔵 函数式宏")
      table.insert(content, "```")
    else
      -- 普通宏定义
      table.insert(content, "```c")
      table.insert(content, macro_definition.definition .. " // 📌 常量宏")
      table.insert(content, "```")
    end
    table.insert(content, "")

    -- 如果有展开内容，显示它，并分析是否包含函数调用
    if macro_definition.expansion and macro_definition.expansion ~= "" then
      table.insert(content, "**🔧 Expansion:**")

      -- 检查展开内容是否包含函数调用
      if string.find(macro_definition.expansion, "(", 1, true) and string.find(macro_definition.expansion, ")", 1, true) then
        table.insert(content, "```c")
        table.insert(content, macro_definition.expansion .. " // 🔄 函数调用/表达式")
        table.insert(content, "```")
      else
        table.insert(content, "```c")
        table.insert(content, macro_definition.expansion .. " // 💾 常量值")
        table.insert(content, "```")
      end
      table.insert(content, "")
    end

    table.insert(content, "> 💡 Press 'q' or move cursor to close")

    -- 使用彩色高亮显示本地宏定义
    vim.lsp.util.open_floating_preview(
      content,
      "c",
      {
        border = {"┌", "─", "┐", "│", "┘", "─", "└", "│"},
        focusable = true,
        close_events = {"CursorMoved", "BufHidden", "InsertCharPre", "BufLeave"},
        title = " ⚡ Local Macro ",
        title_pos = "center",
        max_width = 100,
        max_height = 20,
        wrap = true,
        style = "minimal",
        winhighlight = "Normal:MacroFloatNormal,FloatBorder:MacroFloatBorder,FloatTitle:MacroFloatTitle"
      }
    )
    return true
  end
  return false
end

-- clangd 特定的宏展开功能
local function clangd_expand_macro()
  local bufnr = vim.api.nvim_get_current_buf()
  local clangd_client = require("lspconfig.util").get_active_client_by_name(bufnr, "clangd")

  if not clangd_client then
    show_macro_expansion() -- 回退到通用方法
    return
  end

  local params = vim.lsp.util.make_position_params(0, clangd_client.offset_encoding)
  clangd_client.request(
    "textDocument/semanticTokens/range",
    {
      textDocument = params.textDocument,
      range = {
        start = params.position,
        ["end"] = params.position
      }
    },
    function(err, result)
      if err or not result then
        show_macro_expansion() -- 回退到通用方法
        return
      end
      -- 处理 clangd 的语义标记结果
      show_macro_expansion()
    end,
    bufnr
  )
end

-- 设置自动命令和快捷键
vim.api.nvim_create_autocmd(
  "FileType",
  {
    pattern = {"c", "cpp", "h", "hpp", "cuda"},
    callback = function()
      -- 为 C/C++ 文件设置宏展开快捷键
      vim.keymap.set(
        "n",
        "<leader>me",
        clangd_expand_macro,
        {
          buffer = true,
          desc = "Expand macro under cursor"
        }
      )

      -- 悬浮时自动显示宏信息 (可选)
      -- vim.keymap.set("n", "K", function()
      --   vim.lsp.buf.hover()
      --   vim.defer_fn(show_macro_expansion, 100)
      -- end, { buffer = true, desc = "Hover with macro expansion" })
    end
  }
)

-- 通用的宏展开快捷键
vim.keymap.set(
  "n",
  "<leader>mx",
  show_macro_expansion,
  {
    desc = "Show macro expansion"
  }
)

-- 设置更短的悬停时间
vim.opt.updatetime = 700

-- -- 设置浮动窗口的多色高亮组 - 只改字体颜色
-- vim.api.nvim_set_hl(0, "MacroFloatBorder", {fg = "#8B5CF6", bg = "NONE"}) -- 紫色边框
-- vim.api.nvim_set_hl(0, "MacroFloatTitle", {fg = "#F59E0B", bg = "#1f2937", bold = true}) -- 金色标题
-- vim.api.nvim_set_hl(0, "MacroFloatNormal", {bg = "#0F172A"}) -- 深蓝背景

-- -- 为内容设置不同的字体颜色
-- vim.api.nvim_set_hl(0, "markdownH1", {fg = "#10B981", bold = true}) -- 绿色标题
-- vim.api.nvim_set_hl(0, "markdownH2", {fg = "#EF4444", bold = true}) -- 红色副标题
-- vim.api.nvim_set_hl(0, "markdownCode", {fg = "#A78BFA"}) -- 紫色代码
-- vim.api.nvim_set_hl(0, "markdownCodeBlock", {fg = "#06B6D4"}) -- 青色代码块
-- vim.api.nvim_set_hl(0, "Comment", {fg = "#9CA3AF", italic = true}) -- 灰色注释
-- vim.api.nvim_set_hl(0, "String", {fg = "#34D399"}) -- 绿色字符串
-- vim.api.nvim_set_hl(0, "Number", {fg = "#FBBF24"}) -- 黄色数字
-- vim.api.nvim_set_hl(0, "Keyword", {fg = "#F472B6", bold = true}) -- 粉色关键字

-- -- 函数语法高亮
-- vim.api.nvim_set_hl(0, "Function", {fg = "#60A5FA", bold = true}) -- 蓝色函数名
-- vim.api.nvim_set_hl(0, "Type", {fg = "#F97316", bold = true}) -- 橙色类型/返回值
-- vim.api.nvim_set_hl(0, "Identifier", {fg = "#A855F7"}) -- 紫色标识符/参数名
-- vim.api.nvim_set_hl(0, "Operator", {fg = "#EF4444"}) -- 红色操作符
-- vim.api.nvim_set_hl(0, "Special", {fg = "#00FFFF"}) -- 青色特殊字符

-- CursorHold 事件自动显示宏信息
vim.api.nvim_create_autocmd(
  "CursorHold",
  {
    pattern = {"*.c", "*.cpp", "*.h", "*.hpp", "*.cu", "*.cc", "*.cxx"},
    callback = function()
      local word = vim.fn.expand("<cword>")
      -- 检查是否是可能的宏名称（大写字母开头或包含下划线的标识符）
      if
        word ~= "" and
          (string.match(word, "^[A-Z_][A-Z0-9_]*$") or -- 全大写宏
            string.match(word, "^[a-zA-Z_][a-zA-Z0-9_]*$"))
       then -- 普通标识符
        -- 延迟执行，避免频繁触发
        vim.defer_fn(
          function()
            show_macro_expansion()
          end,
          200
        )
      end
    end
  }
)

-- 为所有文件类型启用悬浮预览（不仅仅是 C/C++）
vim.api.nvim_create_autocmd(
  "CursorHold",
  {
    pattern = "*",
    callback = function()
      local filetype = vim.bo.filetype
      -- 跳过特殊文件类型
      if filetype == "help" or filetype == "man" or filetype == "qf" then
        return
      end

      local word = vim.fn.expand("<cword>")
      if word ~= "" and string.len(word) > 2 then
        -- 对于非 C/C++ 文件，使用更宽松的条件
        vim.defer_fn(
          function()
            show_macro_expansion()
          end,
          300
        )
      end
    end
  }
)

-- 强化透明效果设置
vim.api.nvim_create_autocmd(
  "ColorScheme",
  {
    pattern = "*",
    callback = function()
      -- 确保背景透明
      vim.api.nvim_set_hl(0, "Normal", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "NormalNC", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "NormalFloat", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "FloatBorder", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "SignColumn", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "StatusLine", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "StatusLineNC", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "LineNr", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "CursorLineNr", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "CursorLine", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "EndOfBuffer", {bg = "NONE", ctermbg = "NONE"})

      -- 侧边栏透明
      vim.api.nvim_set_hl(0, "NeoTreeNormal", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "NeoTreeNormalNC", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "NvimTreeNormal", {bg = "NONE", ctermbg = "NONE"})

      -- Telescope 透明
      vim.api.nvim_set_hl(0, "TelescopeNormal", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "TelescopeBorder", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "TelescopePromptNormal", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "TelescopeResultsNormal", {bg = "NONE", ctermbg = "NONE"})
      vim.api.nvim_set_hl(0, "TelescopePreviewNormal", {bg = "NONE", ctermbg = "NONE"})
    end
  }
)

-- 立即应用透明设置
vim.defer_fn(
  function()
    vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
    vim.cmd("hi NormalNC guibg=NONE ctermbg=NONE")
    vim.cmd("hi SignColumn guibg=NONE ctermbg=NONE")
    vim.cmd("hi StatusLine guibg=NONE ctermbg=NONE")
    vim.cmd("hi StatusLineNC guibg=NONE ctermbg=NONE")
    vim.cmd("hi LineNr guibg=NONE ctermbg=NONE")
    vim.cmd("hi CursorLineNr guibg=NONE ctermbg=NONE")
    vim.cmd("hi EndOfBuffer guibg=NONE ctermbg=NONE")
  end,
  100
)

vim.g.airline_extensions_tabline_formatter = "default"
vim.g.airline_section_y = 'BN: %{bufnr("%")}'
vim.g.airline_theme = "monokai"

vim.g.clang_format_style_options = {
  AccessModifierOffset = -4,
  AllowShortIfStatementsOnASingleLine = "true",
  AlwaysBreakTemplateDeclarations = "true",
  Standard = "C++23",
  BreakBeforeBraces = "Stroustrup"
}

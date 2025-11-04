---@type LazySpec
return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
      "onsails/lspkind-nvim",
    },
    config = function()
      local ok, cmp = pcall(require, "cmp")
      if not ok then return end
      local lspkind_ok, lspkind = pcall(require, "lspkind")
      if not lspkind_ok then lspkind = nil end

      local luasnip_ok, luasnip = pcall(require, "luasnip")
      if not luasnip_ok then luasnip = nil end

      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      cmp.setup {
        snippet = {
          expand = function(args)
            if luasnip then luasnip.lsp_expand(args.body) end
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip and luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip and luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
        }),
        formatting = {
          format = (lspkind and lspkind.cmp_format({ with_text = true, maxwidth = 60 })) or nil,
        },
        window = {
          documentation = cmp.config.window.bordered({ winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder" }),
        },
        experimental = {
          ghost_text = true,
        },
      }

      -- Optional: also enable cmp in commandline
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {{ name = "buffer" }},
      })
    end,
  },
}

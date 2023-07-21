local on_attach = function(client, bufnr)
	require("plugins.lsp.codelens").on_attach(client, bufnr)
	require("plugins.lsp.highlight").on_attach(client, bufnr)
	require("plugins.lsp.hover").on_attach(client, bufnr)
	require("plugins.lsp.format").on_attach(client, bufnr)
	require("plugins.lsp.keymap").on_attach(client, bufnr)
	if client.server_capabilities.documentSymbolProvider then
		require("nvim-navic").attach(client, bufnr)
	end
end

return {
	{
		"folke/neoconf.nvim",
		config = true,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "folke/neoconf.nvim" },
	},
	{
		"jose-elias-alvarez/null-ls.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"neovim/nvim-lspconfig",
			"williamboman/mason.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.code_actions.cspell,
					null_ls.builtins.code_actions.gitrebase,
					null_ls.builtins.code_actions.gitsigns,
					null_ls.builtins.code_actions.gomodifytags,
					null_ls.builtins.code_actions.shellcheck,
					null_ls.builtins.completion.vsnip,
					null_ls.builtins.diagnostics.commitlint,
					null_ls.builtins.diagnostics.cpplint,
					null_ls.builtins.diagnostics.fish,
					null_ls.builtins.diagnostics.gitlint,
					null_ls.builtins.diagnostics.golangci_lint,
					null_ls.builtins.diagnostics.jsonlint,
					null_ls.builtins.diagnostics.markdownlint,
					null_ls.builtins.diagnostics.pylint,
					null_ls.builtins.diagnostics.shellcheck,
					null_ls.builtins.diagnostics.staticcheck,
					null_ls.builtins.diagnostics.vale,
					null_ls.builtins.diagnostics.write_good,
					null_ls.builtins.diagnostics.yamllint,
					null_ls.builtins.formatting.black,
					null_ls.builtins.formatting.clang_format,
					null_ls.builtins.formatting.elm_format,
					null_ls.builtins.formatting.fish_indent,
					null_ls.builtins.formatting.fourmolu,
					null_ls.builtins.formatting.gofmt,
					null_ls.builtins.formatting.gofumpt,
					null_ls.builtins.formatting.goimports,
					null_ls.builtins.formatting.golines.with({
						extra_args = { "--max-len=108" },
					}),
					null_ls.builtins.formatting.isort,
					null_ls.builtins.formatting.jq,
					null_ls.builtins.formatting.markdownlint,
					null_ls.builtins.formatting.prettierd,
					null_ls.builtins.formatting.shellharden,
					null_ls.builtins.diagnostics.sqlfluff.with({
						extra_args = { "--dialect", "postgres" },
					}),
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.trim_newlines,
					null_ls.builtins.formatting.trim_whitespace,
					null_ls.builtins.formatting.yamlfmt,
					null_ls.builtins.formatting.zigfmt,
				},
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			local capabilities =
				require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
			local lsp_handlers = {
				function(server_name)
					require("lspconfig")[server_name].setup({
						on_attach = on_attach,
						capabilities = capabilities,
					})
				end,
				["lua_ls"] = function()
					require("lspconfig").lua_ls.setup({
						on_attach = on_attach,
						capabilities = capabilities,
						settings = {
							Lua = {
								runtime = {
									version = "LuaJIT",
								},
								diagnostics = {
									globals = { "vim" },
								},
								workspace = {
									-- Make the server aware of Neovim runtime files.
									library = vim.api.nvim_get_runtime_file("", true),
								},
							},
						},
					})
				end,
				["yamlls"] = function()
					require("lspconfig").yamlls.setup({
						settings = {
							yaml = {
								schemaStore = {
									-- You must disable built-in schemaStore support if you want to use
									-- this plugin and its advanced options like `ignore`.
									enable = false,
								},
								schemas = require("schemastore").yaml.schemas(),
							},
						},
					})
				end,
			}
			require("mason-lspconfig").setup()
			require("mason-lspconfig").setup_handlers(lsp_handlers)
		end,
	},
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"hrsh7th/cmp-vsnip",
	"hrsh7th/vim-vsnip",
	"petertriho/cmp-git",
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-vsnip",
			"hrsh7th/vim-vsnip",
			"petertriho/cmp-git",
		},
		config = function()
			vim.o.completeopt = "menu,menuone,noselect"
			local cmp = require("cmp")

			cmp.setup({
				snippet = {
					-- REQUIRED - you must specify a snippet engine.
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end,
				},
				window = {
					-- completion = cmp.config.window.bordered(),
					-- documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "vsnip" },
				}, {
					{ name = "buffer" },
				}),
			})

			-- Set configuration for specific filetype.
			cmp.setup.filetype("gitcommit", {
				sources = cmp.config.sources({
					{ name = "cmp_git" },
				}, {
					{ name = "buffer" },
				}),
			})

			-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})
		end,
	},
	{
		"github/copilot.vim",
		config = function()
			vim.g.copilot_no_tab_map = true
			-- Accept Copilot suggestion with <C-J>.
			vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
		end,
	},
}

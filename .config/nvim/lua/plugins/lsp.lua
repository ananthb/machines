return {
	"neovim/nvim-lspconfig",
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "ms-jpq/coq_nvim", "github/copilot.vim" },
		config = function()
			-- on_attach runs when an LSP attaches to a buffer
			local on_attach = function(client, bufnr)
				if client.server_capabilities.documentSymbolProvider then
					require("nvim-navic").attach(client, bufnr)
				end

				local nmap = function(keys, func, desc)
					if desc then
						desc = "LSP: " .. desc
					end

					vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
				end

				nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
				nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

				nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
				nmap("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
				nmap("gr", require("telescope.builtin").lsp_references)
				nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
				nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

				-- See `:help K` for why this keymap
				nmap("K", vim.lsp.buf.hover, "Hover Documentation")
				nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

				-- Lesser used LSP functionality
				nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
				nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
				nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
				nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
				nmap("<leader>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, "[W]orkspace [L]ist Folders")

				-- Create a command `:Format` local to the LSP buffer
				vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
					if vim.lsp.buf.format then
						vim.lsp.buf.format()
					elseif vim.lsp.buf.formatting then
						vim.lsp.buf.formatting()
					end
				end, { desc = "Format current buffer with LSP" })
			end

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local coq_capabilities = require("coq").lsp_ensure_capabilities()

			-- LSP Servers to install and setup
			mason_lspconfig.setup({
				ensure_installed = {
					"bashls",
					"clangd",
					"cmake",
					"dockerls",
					"elmls",
					"gopls",
					"jsonls",
					"marksman",
					"pyright",
					"rust_analyzer",
					"sqls",
					"yamlls",
					"zls",
				},
			})

			mason_lspconfig.setup_handlers({
				function(server_name)
					lspconfig[server_name].setup({
						on_attach = on_attach,
						capabilities = capabilities,
					})
					lspconfig[server_name].setup(coq_capabilities)
				end,
				["sumneko_lua"] = function()
					lspconfig.sumneko_lua.setup({
						on_attach = on_attach,
						capabilities = capabilities,
						settings = {
							Lua = {
								diagnostics = {
									globals = { "vim" },
								},
							},
						},
					})
					lspconfig.sumneko_lua.setup(coq_capabilities)
				end,
			})

			-- start COQ
			vim.cmd("COQnow -s")
		end,
	},
}

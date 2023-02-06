local on_attach = function(client, bufnr)
	local navic = require("nvim-navic")
	local telescope_builtin = require("telescope.builtin")

	if client.server_capabilities.documentSymbolProvider then
		navic.attach(client, bufnr)
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
	nmap("gr", telescope_builtin.lsp_references)
	nmap("<leader>ds", telescope_builtin.lsp_document_symbols, "[D]ocument [S]ymbols")
	nmap("<leader>ws", telescope_builtin.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

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

return {
	"neovim/nvim-lspconfig",
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"SmiteshP/nvim-navic",
			"nvim-telescope/telescope.nvim",
			"ms-jpq/coq_nvim",
			"github/copilot.vim",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")
			local coq = require("coq")

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
					lspconfig[server_name].setup(coq.lsp_ensure_capabilities({
						on_attach = on_attach,
					}))
				end,
				["sumneko_lua"] = function()
					lspconfig.sumneko_lua.setup(coq.lsp_ensure_capabilities({
						on_attach = on_attach,
						settings = {
							Lua = {
								diagnostics = {
									globals = { "vim" },
								},
							},
						},
					}))
				end,
			})

			-- start COQ
			vim.cmd("COQnow -s")
		end,
	},
}

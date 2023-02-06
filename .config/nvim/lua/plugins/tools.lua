-- DEV TOOLS
return {
	"williamboman/mason.nvim",
	-- MASON INSTALLER
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"black",
					"clang-format",
					"cpplint",
					"elm-format",
					"eslint-lsp",
					"flake8",
					"goimports",
					"golangci-lint",
					"html-lsp",
					"jq",
					"lua-language-server",
					"markdownlint",
					"mypy",
					"prettier",
					"pylint",
					"shellcheck",
					"shfmt",
					"sql-formatter",
					"staticcheck",
					"stylua",
					"yamlfmt",
					"yamllint",
				},
			})
		end,
	},
	{
		"ms-jpq/coq_nvim",
		branch = "coq",
		dependencies = { "ms-jpq/coq.artifacts", branch = "artifacts" },
		build = ":COQdeps",
	},
	{
		"github/copilot.vim",
		config = function()
			vim.g.copilot_no_tab_map = true
			vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
		end,
	},
	-- DAP
	{
		"mfussenegger/nvim-dap",
		config = function()
			require("dap.ext.vscode").load_launchjs(nil, {})
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-nvim-dap").setup({
				ensure_installed = { "python", "delve" },
			})
		end,
	},
	{ "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap" } },
	"theHamsta/nvim-dap-virtual-text",
	-- GIT
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
	{
		"lewis6991/gitsigns.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("gitsigns").setup()
		end,
	},
	"f-person/git-blame.nvim",
	-- TREESITTER
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"c",
					"cpp",
					"css",
					"dockerfile",
					"elm",
					"fish",
					"go",
					"gomod",
					"haskell",
					"javascript",
					"json",
					"lua",
					"make",
					"python",
					"toml",
					"typescript",
					"yaml",
					"zig",
				},
				auto_install = true,
			})
		end,
	},
}

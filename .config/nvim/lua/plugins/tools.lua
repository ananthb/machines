return {
	-- MASON TOOLS
	{
		"williamboman/mason.nvim",
		opts = {},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
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
				auto_update = true,
			})
		end,
	},
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

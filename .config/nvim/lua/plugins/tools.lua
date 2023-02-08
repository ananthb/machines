return {
	-- MASON TOOLS
	"williamboman/mason.nvim",
	"williamboman/mason-lspconfig.nvim",
	"WhoIsSethDaniel/mason-tool-installer.nvim",
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

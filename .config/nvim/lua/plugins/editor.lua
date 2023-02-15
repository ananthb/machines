return {
	{
		"ggandor/leap.nvim",
		config = function()
			require("leap").set_default_keymaps()
		end,
	},
	"tpope/vim-sleuth",
	"tpope/vim-repeat",
	"tpope/vim-speeddating",
	"kylechui/nvim-surround",
	{
		"mhartington/formatter.nvim",
		config = function()
			-- Format on save.
			vim.api.nvim_create_autocmd("BufWritePost", {
				command = "FormatWrite",
				pattern = "*",
			})
			require("formatter").setup({
				filetype = {
					["*"] = {
						require("formatter.filetypes.any").remove_trailing_whitespace,
					},
					lua = {
						require("formatter.filetypes.lua").stylua,
					},
					go = {
						require("formatter.filetypes.go").gofmt,
						require("formatter.filetypes.go").gofumpt,
						require("formatter.filetypes.go").goimports,
						require("formatter.filetypes.go").golines(),
					},
				},
			})
		end,
	},
}

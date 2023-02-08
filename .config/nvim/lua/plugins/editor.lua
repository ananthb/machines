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
					},
				},
			})
		end,
	},
}

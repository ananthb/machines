return {
	{
		"ggandor/leap.nvim",
		config = function()
			require("leap").add_default_mappings()
		end,
	},
	"tpope/vim-sleuth",
	"tpope/vim-repeat",
	"tpope/vim-speeddating",
	"kylechui/nvim-surround",
	"andymass/vim-matchup",
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = true,
	},
}

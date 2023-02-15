return {
	-- GOLANG
	{
		"ray-x/go.nvim",
		dependencies = {
			"ray-x/guihua.lua",
			"nvim-treesitter/nvim-treesitter",
			"neovim/nvim-lspconfig",
		},
		config = true,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync',
	},
}

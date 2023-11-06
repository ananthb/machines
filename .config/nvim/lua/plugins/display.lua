return {
	"nvim-lua/plenary.nvim",
	{
		"bluz71/vim-moonfly-colors",
		priority = 1000,
		config = function()
			vim.cmd([[colorscheme moonfly]])
		end,
	},
	"stevearc/dressing.nvim",
	{
		"ellisonleao/glow.nvim",
		config = true,
		cmd = "Glow",
	},
	{
		"folke/which-key.nvim",
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			require("which-key").setup()
		end,
	},
	{
		"SmiteshP/nvim-navic",
		dependencies = "neovim/nvim-lspconfig",
	},
	{
		"utilyre/barbecue.nvim",
		name = "barbecue",
		version = "*",
		dependencies = {
			"SmiteshP/nvim-navic",
			"nvim-tree/nvim-web-devicons",
		},
		config = true,
	},
	{
		"akinsho/bufferline.nvim",
		dependencies = "neovim/nvim-lspconfig",
		opts = {
			options = {
				diagnostics = "nvim_lsp",
				offsets = {
					{
						filetype = "NvimTree",
						text = "File Explorer",
						highlight = "Directory",
						text_align = "left",
					},
				},
			},
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		name = "lualine",
		opts = {
			options = {
				icons_enabled = true,
				theme = "auto",
			},
		},
	},
	{
		"glepnir/dashboard-nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		event = "VimEnter",
		name = "dashboard",
		opts = {
			theme = "doom",
			config = {
				center = {
					{
						icon = "  ",
						desc = "[S]essions",
						action = "Telescope session-lens search_session",
						key = "s",
					},
					{
						icon = "  ",
						desc = "[F]iles",
						action = "Telescope find_files",
						key = "f",
					},
					{
						icon = "  ",
						desc = "[G]rep",
						action = "Telescope live_grep",
						key = "g",
					},
					{
						icon = "  ",
						desc = "[H]elp",
						action = "Telescope help_tags",
						key = "h",
					},
					{
						icon = "  ",
						desc = "[B]uffers",
						action = "Telescope buffers",
						key = "b",
					},
				},
			},
		},
	},
	{
		"folke/trouble.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = true,
	},
}

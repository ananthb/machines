local function open_nvim_tree(data)
	-- Buffer is a directory.
	local directory = vim.fn.isdirectory(data.file) == 1

	if not directory then
		return
	end

	-- Change to the directory.
	vim.cmd.cd(data.file)

	-- Open the tree.
	require("nvim-tree.api").tree.open()
end

return {
	"nvim-lua/plenary.nvim",
	{
		"bluz71/vim-moonfly-colors",
		priority = 1000,
		config = function()
			vim.cmd([[colorscheme moonfly]])
		end,
	},
	-- GLOW markdown
	{
		"ellisonleao/glow.nvim",
		config = true,
		cmd = "Glow",
	},
	-- WHICH KEY
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
	-- NVIM TREE
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			vim.keymap.set("n", "<C-n>", require("nvim-tree.api").tree.toggle, { desc = "Toggle Nvim Tree" })
			vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
			require("nvim-tree").setup({
				sync_root_with_cwd = true,
			})
		end,
	},
}

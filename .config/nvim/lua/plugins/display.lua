local function open_nvim_tree(data)
	-- buffer is a directory
	local directory = vim.fn.isdirectory(data.file) == 1

	if not directory then
		return
	end

	-- change to the directory
	vim.cmd.cd(data.file)

	-- open the tree
	require("nvim-tree.api").tree.open()
end

return {
	"bluz71/vim-moonfly-colors",
	"nvim-lua/popup.nvim",
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
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					icons_enabled = true,
					theme = "auto",
				},
			})
		end,
	},
	{
		"glepnir/dashboard-nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		event = "VimEnter",
		config = function()
			require("dashboard").setup({
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
			})
		end,
	},
	{
		"folke/trouble.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			require("trouble").setup({})
		end,
	},
	-- NVIM TREE
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup({
				sync_root_with_cwd = true,
			})
			vim.keymap.set("n", "<C-n>", require("nvim-tree.api").tree.toggle, { desc = "Toggle Nvim Tree" })
			vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
		end,
	},
}

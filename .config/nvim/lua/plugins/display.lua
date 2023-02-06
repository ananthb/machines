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
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "SmiteshP/nvim-navic" },
		config = function()
			local navic = require("nvim-navic")
			require("lualine").setup({
				options = {
					icons_enabled = true,
					theme = "auto",
				},
				sections = {
					lualine_c = {
						{ "filename", { navic.get_location, cond = navic.is_available } },
					},
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
		"SmiteshP/nvim-navic",
		dependencies = "neovim/nvim-lspconfig",
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

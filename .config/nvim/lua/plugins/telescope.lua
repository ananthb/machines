return {
	-- Build telescope fzf native if make is available.
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
		cond = vim.fn.executable("make") == 1,
	},
	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	},
	{
		"nvim-telescope/telescope.nvim",
		version = "0.1.x",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-fzf-native.nvim" },
		config = function()
			local scope = require("telescope")
			scope.setup({
				defaults = {
					mappings = {
						i = {
							["<C-u>"] = false,
							["<C-d>"] = false,
						},
					},
				},
			})

			-- Enable telescope fzf native, if installed.
			pcall(scope.load_extension, "fzf")

			scope.load_extension("file_browser")

			-- See `:help telescope.builtin`.
			local telescope_builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>?", telescope_builtin.oldfiles, { desc = "Find recently opened files" })
			vim.keymap.set("n", "<leader><space>", telescope_builtin.buffers, { desc = "Find existing buffers" })
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to telescope to change theme, layout, etc.
				telescope_builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "Fuzzy search current buffer" })

			vim.keymap.set("n", "<leader>ss", require("session-lens").search_session, { desc = "Search sessions" })
			vim.keymap.set("n", "<leader>sf", telescope_builtin.find_files, { desc = "Search files" })
			vim.keymap.set("n", "<leader>sh", telescope_builtin.help_tags, { desc = "Search Help" })
			vim.keymap.set("n", "<leader>sw", telescope_builtin.grep_string, { desc = "Search current word" })
			vim.keymap.set("n", "<leader>sg", telescope_builtin.live_grep, { desc = "Search by grep" })
			vim.keymap.set("n", "<leader>fb", "<Cmd>Telescope file_browser<CR>", { desc = "Open file browser" })
		end,
	},
}

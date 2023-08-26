return {
	{
		"rmagatti/auto-session",
		name = "auto-session",
		opts = {
			auto_session_enabled = true,
			auto_save_enabled = true,
			auto_restore_enabled = true,
			auto_session_supress_dirs = { "~" },
			auto_session_allowed_dirs = { "~/src/*" },
			auto_session_enable_last_session = vim.g.neovide and vim.loop.cwd() == vim.loop.os_homedir(),
		},
	},
	{
		"rmagatti/session-lens",
		dependencies = { "rmagatti/auto-session", "nvim-telescope/telescope.nvim" },
		name = "session-lens",
		config = true,
	},
}

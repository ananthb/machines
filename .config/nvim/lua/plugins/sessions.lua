return {
	{
		"rmagatti/auto-session",
		name = "auto-session",
		opts = {
			auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
			auto_session_enabled = true,
			auto_save_enabled = true,
			auto_restore_enabled = true,
			auto_session_supress_dirs = { "~" },
			auto_session_allowed_dirs = { "~/src/*" },
		},
	},
	{
		"rmagatti/session-lens",
		dependencies = { "rmagatti/auto-session", "nvim-telescope/telescope.nvim" },
		name = "session-lens",
		opts = {},
	},
}

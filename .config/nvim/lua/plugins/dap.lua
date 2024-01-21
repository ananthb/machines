return {
	{
		"mfussenegger/nvim-dap",
		cond = not vim.g.started_by_firenvim,
		config = function()
			require("dap.ext.vscode").load_launchjs(nil, {})
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		cond = not vim.g.started_by_firenvim,
		dependencies = { "williamboman/mason.nvim" },
		name = "mason-nvim-dap",
		opts = {
			ensure_installed = { "python", "delve" },
		},
	},
	{
		"rcarriga/nvim-dap-ui",
		cond = not vim.g.started_by_firenvim,
		dependencies = { "mfussenegger/nvim-dap" },
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		cond = not vim.g.started_by_firenvim,
	},
}

return {
	{
		"mfussenegger/nvim-dap",
		config = function()
			require("dap.ext.vscode").load_launchjs(nil, {})
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = { "williamboman/mason.nvim" },
		name = "mason-nvim-dap",
		opts = {
			ensure_installed = { "python", "delve" },
		},
	},
	{ "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap" } },
	"theHamsta/nvim-dap-virtual-text",
}

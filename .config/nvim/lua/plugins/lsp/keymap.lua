local M = {}

local format = require("plugins.lsp.format").format

local function diagnostic_goto(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		go({ severity = severity })
	end
end

local keymap = {
	-- Goto stuff.
	{ "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "Goto Definition" },
	{ "gr", "<cmd>Telescope lsp_references<cr>", desc = "References" },
	{ "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
	{ "gI", "<cmd>Telescope lsp_implementations<cr>", desc = "Goto Implementation" },
	{ "gt", "<cmd>Telescope lsp_type_definitions<cr>", desc = "Goto Type Definition" },
	{ "K", vim.lsp.buf.hover, desc = "Hover" },
	{ "gK", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
	{
		"<c-k>",
		vim.lsp.buf.signature_help,
		mode = "i",
		desc = "Signature Help",
		has = "signatureHelp",
	},
	-- Diagnostic.
	{ "]d", diagnostic_goto(true), desc = "Next Diagnostic" },
	{ "[d", diagnostic_goto(false), desc = "Prev Diagnostic" },
	{ "]e", diagnostic_goto(true, "ERROR"), desc = "Next Error" },
	{ "[e", diagnostic_goto(false, "ERROR"), desc = "Prev Error" },
	{ "]w", diagnostic_goto(true, "WARN"), desc = "Next Warning" },
	{ "[w", diagnostic_goto(false, "WARN"), desc = "Prev Warning" },
	{ "<leader>cd", vim.diagnostic.open_float, desc = "Open diagnostic" },
	{ "<leader>cl", vim.diagnostic.setloclist, desc = "Add diagnostic to location list" },
	-- Code.
	{
		"<leader>ca",
		vim.lsp.buf.code_action,
		desc = "Code Action",
		mode = { "n", "v" },
		has = "codeAction",
	},
	{
		"<leader>cf",
		format,
		desc = "Format Document",
		has = "documentFormatting",
	},
	{
		"<leader>cf",
		format,
		desc = "Format Range",
		mode = "v",
		has = "documentRangeFormatting",
	},
	{
		"<leader>cl",
		vim.lsp.codelens.run,
		desc = "Run Code Lens on current line",
		has = "codeLens",
	},
	{ "<leader>cn", "<cmd>LspInfo<cr>", desc = "LSP Info" },
	{ "<leader>rn", vim.lsp.buf.rename, desc = "Rename" },
	-- Workspaces.
	{ "<leader>wa", vim.lsp.buf.add_workspace_folder, desc = "Add Workspace Folder" },
	{ "<leader>wr", vim.lsp.buf.remove_workspace_folder, desc = "Remove Workspace Folder" },
	{
		"<leader>wl",
		function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end,
		desc = "List Workspace Folders",
	},
}

---@param method string
local function has(client, method)
	method = method:find("/") and method or "textDocument/" .. method
	return client.supports_method(method)
end

function M.on_attach(client, _)
	for _, keys in pairs(keymap) do
		if not keys.has or has(client, keys.has) then
			local opts = {}
			opts.silent = opts.silent ~= false
			if keys.desc then
				opts.desc = keys.desc
			end
			opts.silent = opts.silent ~= false
			vim.keymap.set(keys.mode or "n", keys[1], keys[2], opts)
		end
	end
end

return M

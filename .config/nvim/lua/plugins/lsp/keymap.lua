local M = {}

local format = require("plugins.lsp.format").format

function M.diagnostic_goto(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		go({ severity = severity })
	end
end

M.keymap = {
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
	{ "]d", M.diagnostic_goto(true), desc = "Next Diagnostic" },
	{ "[d", M.diagnostic_goto(false), desc = "Prev Diagnostic" },
	{ "]e", M.diagnostic_goto(true, "ERROR"), desc = "Next Error" },
	{ "[e", M.diagnostic_goto(false, "ERROR"), desc = "Prev Error" },
	{ "]w", M.diagnostic_goto(true, "WARN"), desc = "Next Warning" },
	{ "[w", M.diagnostic_goto(false, "WARN"), desc = "Prev Warning" },
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

function M.on_attach(client, buffer)
	local Keys = require("lazy.core.handler.keys")
	local keymap = {} ---@type table<string,LazyKeys|{has?:string}>
	for _, value in ipairs(M.keymap) do
		local keys = Keys.parse(value)
		if keys[2] == vim.NIL or keys[2] == false then
			keymap[keys.id] = nil
		else
			keymap[keys.id] = keys
		end
	end
	for _, keys in pairs(keymap) do
		if not keys.has or client.server_capabilities[keys.has .. "Provider"] then
			local opts = Keys.opts(keys)
			---@diagnostic disable-next-line: no-unknown
			opts.has = nil
			opts.silent = true
			opts.buffer = buffer
			vim.keymap.set(keys.mode or "n", keys[1], keys[2], opts)
		end
	end
end

return M

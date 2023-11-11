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
function M.has(buffer, method)
	method = method:find("/") and method or "textDocument/" .. method
	local clients = require("lazyvim.util").lsp.get_clients({ bufnr = buffer })
	for _, client in ipairs(clients) do
		if client.supports_method(method) then
			return true
		end
	end
	return false
end

---@return (LazyKeys|{has?:string})[]
function M.resolve(buffer)
	local Keys = require("lazy.core.handler.keys")
	if not Keys.resolve then
		return {}
	end
	local opts = require("lazyvim.util").opts("nvim-lspconfig")
	local clients = require("lazyvim.util").lsp.get_clients({ bufnr = buffer })
	for _, client in ipairs(clients) do
		local maps = opts.servers[client.name] and opts.servers[client.name].keys or {}
		vim.list_extend(M.keymap, maps)
	end
	return Keys.resolve(M.keymap)
end

function M.on_attach(_, buffer)
	local Keys = require("lazy.core.handler.keys")
	local keymaps = M.resolve(buffer)

	for _, keys in pairs(keymaps) do
		if not keys.has or M.has(buffer, keys.has) then
			local opts = Keys.opts(keys)
			opts.has = nil
			opts.silent = opts.silent ~= false
			opts.buffer = buffer
			vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
		end
	end
end

return M

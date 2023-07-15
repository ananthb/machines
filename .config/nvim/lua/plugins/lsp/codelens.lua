local M = {}

function M.on_attach(client, buf)
	if not client.supports_method("textDocument/codeLens") then
		return
	end
	local group = vim.api.nvim_create_augroup("LspCodeLens." .. buf, {})
	vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
		group = group,
		buffer = buf,
		callback = vim.lsp.codelens.refresh,
	})
end

return M

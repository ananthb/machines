local M = {}

function M.on_attach(client, buf)
	if not client.supports_method("textDocument/documentHighlight") then
		return
	end

	local group = vim.api.nvim_create_augroup("LspDocumentHighlight." .. buf, {})
	vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
		group = group,
		buffer = buf,
		callback = vim.lsp.buf.document_highlight,
	})
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = group,
		buffer = buf,
		callback = vim.lsp.buf.clear_references,
	})
end

return M

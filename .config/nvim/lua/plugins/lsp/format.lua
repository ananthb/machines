local M = {}

function M.format()
	local buf = vim.api.nvim_get_current_buf()
	if vim.b.autoformat == false then
		return
	end
	local ft = vim.bo[buf].filetype
	local have_nls = #require("null-ls.sources").get_available(ft, "NULL_LS_FORMATTING") > 0

	vim.lsp.buf.format({
		bufnr = buf,
		filter = function(client)
			if have_nls then
				return client.name == "null-ls"
			end
			return client.name ~= "null-ls"
		end,
	})
end

function M.on_attach(client, buf)
	-- Don't format if client disabled it or doesn't support it.
	if
		(
			client.config
			and client.config.capabilities
			and client.config.capabilities.documentFormattingProvider == false
		) or not client.supports_method("textDocument/formatting")
	then
		return
	end

	-- Create a command `:Format` local to the LSP buffer.
	vim.api.nvim_buf_create_user_command(buf, "Format", M.format, { desc = "Format current buffer" })
	local group = vim.api.nvim_create_augroup("LspFormat." .. buf, {})
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group,
		buffer = buf,
		callback = function()
			M.format()
		end,
	})
end

return M

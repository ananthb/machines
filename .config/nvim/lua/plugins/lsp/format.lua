local M = {}

function M.null_ls_sources()
	local null_ls = require("null-ls")
	return {
		null_ls.builtins.code_actions.gitrebase,
		null_ls.builtins.code_actions.gitsigns,
		null_ls.builtins.code_actions.gomodifytags,
		null_ls.builtins.completion.vsnip,
		null_ls.builtins.diagnostics.commitlint,
		null_ls.builtins.diagnostics.fish,
		null_ls.builtins.diagnostics.gitlint,
		null_ls.builtins.diagnostics.golangci_lint,
		null_ls.builtins.diagnostics.markdownlint,
		null_ls.builtins.diagnostics.pylint,
		null_ls.builtins.diagnostics.staticcheck,
		null_ls.builtins.diagnostics.vale,
		null_ls.builtins.diagnostics.write_good,
		null_ls.builtins.diagnostics.yamllint,
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.clang_format,
		null_ls.builtins.formatting.elm_format,
		null_ls.builtins.formatting.fish_indent,
		null_ls.builtins.formatting.gofmt,
		null_ls.builtins.formatting.goimports,
		null_ls.builtins.formatting.isort,
		null_ls.builtins.formatting.markdownlint,
		null_ls.builtins.formatting.shellharden,
		null_ls.builtins.diagnostics.sqlfluff.with({
			extra_args = { "--dialect", "postgres" },
		}),
		null_ls.builtins.formatting.sqlfmt,
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.yamlfmt,
	}
end

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
		callback = M.format,
	})
end

return M

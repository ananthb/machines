local M = {}

local hover_time = 500
local hover_timer = nil
vim.o.nousemoveevent = true

local mousemove_str = vim.api.nvim_replace_termcodes("<MouseMove>", false, false, true)

function M.on_attach(client, _)
	if not (client.supports_method("textDocument/hover") and client.server_capabilities.hoverProvider) then
		return
	end
	vim.on_key(function(str)
		if str == mousemove_str then
			if hover_timer then
				hover_timer:close()
			end
			hover_timer = vim.defer_fn(function()
				hover_timer = nil
				vim.lsp.buf.hover()
			end, hover_time)
		end
	end)
end

return M

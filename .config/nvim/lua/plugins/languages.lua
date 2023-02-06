return {
-- GOLANG
{
	"ray-x/go.nvim",
	requires = { "ray-x/guihua.lua" },
	config = function()
		require("go").setup({})
	end,
}
}


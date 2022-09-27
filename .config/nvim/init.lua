-- PACKER
local install_path = vim.fn.stdpath 'data'
    .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = vim.fn.system({
    'git', 'clone', '--depth', '1',
    'https://github.com/wbthomason/packer.nvim', install_path})
  print('Installing packer. Close and re-open neovim to begin...')
  vim.cmd [[packadd packer.nvim]]
end


-- reload nvim automatically
local packer_group = vim.api.nvim_create_augroup('Packer',
  { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  command = 'source <afile> | PackerCompile',
  group = packer_group,
  pattern = vim.fn.expand '$MYVIMRC',
})



-- use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, 'packer')
if not status_ok then
	print('Packer is NOT OK')
	return
end


packer.startup(function(use)
  use 'wbthomason/packer.nvim'


  -- DISPLAY
  use 'tomasiser/vim-code-dark'
  use 'nvim-lua/popup.nvim'
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    config = function()
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
        },
      }
    end
  }

  use {
    'glepnir/dashboard-nvim',
    config = function()
      local db = require('dashboard')
      db.preview_command = 'cat | lolcat'
      db.preview_file_path = vim.fn.stdpath 'config' .. '/neovim.cat'
      db.preview_file_height = 5
      db.preview_file_width = 55
      db.custom_center = {
        {
          icon = '  ',
          desc = '[S]earch [S]essions          ',
          action = 'Telescope session-lens search_session',
          shortcut = '<space>ss',
        },
        {
          icon = '  ',
          desc = '[S]earch [F]iles             ',
          action = 'Telescope find_files',
          shortcut = '<space>sf',
        },
        {
          icon = '  ',
          desc = '[S]earch by [G]rep           ',
          action = 'Telescope live_grep',
          shortcut = '<space>sg',
        },
        {
          icon = '  ',
          desc = '[S]earch [B]uffers           ',
          action = 'Telescope buffers',
          shortcut = '<space>sb',
        },
        {
          icon = '  ',
          desc = '[S]earch [H]elp              ',
          action = 'Telescope help_tags',
          shortcut = '<space>sh',
        },
      }
    end
  }

  use {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {}
    end
  }


  -- SESSIONS
  use {
    'rmagatti/auto-session',
    config = function()
      require('auto-session').setup {
        auto_session_root_dir = vim.fn.stdpath 'data' .. '/sessions/',
        auto_session_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = true,
        auto_session_supress_dirs = { '~' },
        auto_session_allowed_dirs = { '~/src/*' },
      }
    end
  }
  use {
    'rmagatti/session-lens',
    requires = { 'rmagatti/auto-session', 'nvim-telescope/telescope.nvim' },
    config = function()
      require('session-lens').setup {}
    end
  }


  -- NVIM TREE
  use {
    'kyazdani42/nvim-tree.lua',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      require 'nvim-tree'.setup()
      vim.keymap.set('n', '<C-n>', require 'nvim-tree.api'.tree.toggle,
        { desc = "Toggle Nvim Tree" })
    end
  }


  -- COQ
  use {
    'ms-jpq/coq_nvim', branch = 'coq',
    requires = { 'ms-jpq/coq.artifacts', branch = 'artifacts' }
  }


  -- GIT
  use 'tpope/vim-fugitive'
  use 'tpope/vim-rhubarb'
  use {
    'lewis6991/gitsigns.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('gitsigns').setup {}
    end
  }


  -- TREESITTER
  use {
    'nvim-treesitter/nvim-treesitter',
    requires = { 'nvim-treesitter/nvim-treesitter-textobjects' },
    config = function()
      require 'nvim-treesitter.configs'.setup {
        ensure_installed = {
          'c', 'cpp', 'css', 'dockerfile', 'elm', 'fish', 'go', 'gomod',
          'haskell', 'javascript', 'json', 'lua', 'make', 'python',
          'toml', 'typescript', 'yaml', 'zig'
        },
        auto_install = true,
      }
    end
  }


  -- LSP
  use { 'williamboman/mason.nvim',
    config = function() require 'mason'.setup {} end
  }

 use {
    'williamboman/mason-lspconfig.nvim',
    config = function()
      -- on_attach runs when an LSP attaches to a buffer
      local on_attach = function(_, bufnr)
        local nmap = function(keys, func, desc)
          if desc then
            desc = 'LSP: ' .. desc
          end

          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end

        nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

        nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
        nmap('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
        nmap('gr', require('telescope.builtin').lsp_references)
        nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

        -- See `:help K` for why this keymap
        nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
        nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

        -- Lesser used LSP functionality
        nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        nmap('<leader>D', vim.lsp.buf.type_definition,
          'Type [D]efinition')
        nmap('<leader>wa', vim.lsp.buf.add_workspace_folder,
          '[W]orkspace [A]dd Folder')
        nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder,
          '[W]orkspace [R]emove Folder')
        nmap('<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, '[W]orkspace [L]ist Folders')

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
          if vim.lsp.buf.format then
            vim.lsp.buf.format()
          elseif vim.lsp.buf.formatting then
            vim.lsp.buf.formatting()
          end
        end, { desc = 'Format current buffer with LSP' })
      end

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local lspconfig = require 'lspconfig'
      local mason_lspconfig = require 'mason-lspconfig'

      -- LSP Servers to install and setup
      mason_lspconfig.setup {
        ensure_installed = {
          'bashls', 'clangd', 'cmake', 'dockerls', 'elmls',
          'gopls', 'hls', 'jsonls', 'marksman', 'pyright',
          'rust_analyzer', 'sqls', 'yamlls', 'zls'
        },
      }

      mason_lspconfig.setup_handlers {
        function (server_name)
          lspconfig[server_name].setup {
            on_attach = on_attach,
            capabilities = capabilities,
          }
        end,
        ['sumneko_lua'] = function()
          lspconfig.sumneko_lua.setup {
            settings = {
              Lua = {
                diagnostics = {
                  globals = { 'vim' }
                }
              }
            }
          }
        end
      }
    end
  }

  use 'neovim/nvim-lspconfig'

  use {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    config = function() 
      require 'mason-tool-installer'.setup {
        ensure_installed = {
          'black', 'clang-format', 'cpplint', 'elm-format',
          'eslint-lsp', 'flake8', 'goimports', 'golangci-lint',
          'html-lsp', 'jq', 'lua-language-server', 'markdownlint',
          'mypy', 'prettier', 'pylint', 'shellcheck', 'shfmt',
          'sql-formatter', 'staticcheck', 'stylua',
          'yamlfmt', 'yamllint'
        }
      }
    end
  }


  -- TELESCOPE
  use {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      local scope = require('telescope')
      scope.setup {
        defaults = {
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
            },
          },
        },
      }

      -- enable telescope fzf native, if installed
      pcall(scope.load_extension, 'fzf')

      -- see `:help telescope.builtin`
      local telescope_builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>?', telescope_builtin.oldfiles,
        { desc = '[?] Find recently opened files' })
      vim.keymap.set('n', '<leader><space>', telescope_builtin.buffers,
        { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>/',
        function()
          -- You can pass additional configuration to telescope to
          -- change theme, layout, etc.
          telescope_builtin.current_buffer_fuzzy_find(
            require('telescope.themes').get_dropdown {
              winblend = 10,
              previewer = false,
            })
        end, { desc = '[/] Fuzzily search in current buffer]' })

      vim.keymap.set('n', '<leader>ss',
        require('session-lens').search_session,
        { desc = '[S]earch [S]essions' })
      vim.keymap.set('n', '<leader>sf', telescope_builtin.find_files,
        { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>sh', telescope_builtin.help_tags,
        { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sw', telescope_builtin.grep_string,
        { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', telescope_builtin.live_grep,
        { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sb', telescope_builtin.buffers,
        { desc = '[S]earch [B]uffers' })
    end
  }

  -- build telescope fzf native if make is available
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make',
    cond = vim.fn.executable 'make' == 1
  }


  -- EDITOR
  use {
    'ggandor/leap.nvim',
    config = function()
      require 'leap'.set_default_keymaps()
    end
  }
  use 'ellisonleao/glow.nvim'
  use 'tpope/vim-sleuth'
  use 'kylechui/nvim-surround'
  use {
    'mhartington/formatter.nvim',
    config = function()
      -- format on save
      vim.api.nvim_create_autocmd('BufWritePost', {
        command = 'FormatWrite',
        pattern = '*',
      })

      require('formatter').setup {
        --[[ TODO: re-enable this once MacOS sed issue is fixed
        filetype = {
          ['*'] = {
            require('formatter.filetypes.any').remove_trailing_whitespace
          }
        }
        ]]--
      }
    end
  }


  -- POETRY ENVS
  use 'petobens/poet-v'


  if PACKER_BOOTSTRAP then
    require('packer').sync()
  end
end)


-- stop loading config if bootstrapping
if PACKER_BOOTSTRAP then
  return
end


-- CONFIG
vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1
vim.cmd [[colorscheme codedark]]
vim.o.termguicolors = true
vim.o.updatetime = 250
vim.o.hlsearch = false
vim.o.mouse = 'a'
vim.o.number = true
vim.o.relativenumber = true
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.completeopt = 'menuone,noselect'


-- KEYMAPS
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required
--  (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'",
  { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'",
  { expr = true, silent = true })


-- YANK HIGHLIGHT
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight',
  { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})


-- DIAGNOSTIC KEYMAPS
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- vim: ts=2 sts=2 sw=2 et

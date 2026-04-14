# Reusable development environment: nixvim, git (without identity), direnv, gpg.
# Personal identity, secrets, and packages should be set in the consuming config.
{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    gpg = {
      enable = true;
      publicKeys = [];
      settings = {
        use-agent = true;
      };

      scdaemonSettings = {
        disable-ccid = true;
        reader-port = "Yubico Yubi";
      };
    };

    git = {
      enable = true;
      signing.format = lib.mkDefault null;

      settings = {
        core.editor = "nvim";
        core.pager = "delta";
        init.defaultBranch = "main";

        interactive.diffFilter = "delta --color-only";

        delta = {
          navigate = true;
          side-by-side = true;
          line-numbers = true;
          syntax-theme = "base16-256";
          dark = true;
        };

        alias = {
          a = "add";
          b = "branch";
          c = "commit";
          p = "push";
          r = "reset";
          s = "status -sb";
          sw = "switch";
          co = "checkout";
          cp = "cherry-pick";
          absorb = "absorb";
        };

        color = {
          ui = "true";
          diff = "auto";
          status = "auto";
          branch = "auto";
        };

        advice = {
          pushNonFastForward = "false";
          statusHints = "false";
          commitBeforeMerge = "false";
          resolveConflict = "false";
          implicitIdentity = "false";
          detachedHead = "false";
        };

        push.autoSetupRemote = true;
        rerere.enabled = "true";
        column.ui = "auto";
        branch.sort = "-committerdate";
        merge.conflictStyle = "zdiff3";
        diff.algorithm = "histogram";
        diff.colorMoved = "default";
        transfer.fsckObjects = "true";
        fetch.fsckObjects = "true";
        receive.fsckObjects = "true";
      };
    };

    nix-index-database.comma.enable = true;

    nixvim = {
      enable = true;

      nixpkgs.useGlobalPackages = true;

      opts = {
        number = true;
        relativenumber = true;
        updatetime = 300;
        signcolumn = "yes";
        undofile = true;
        scrolloff = 8;
        splitright = true;
        splitbelow = true;
      };

      globals.mapleader = " ";

      extraConfigLua = ''
        vim.diagnostic.config({
          virtual_text = {
            spacing = 2,
            prefix = "●",
          },
          severity_sort = true,
          float = {
            border = "rounded",
            source = "if_many",
          },
        })

        vim.filetype.add({
          extension = {
            nomad = "nomad",
          },
        })
      '';

      colorschemes.oxocarbon.enable = true;

      plugins = {
        aw-watcher.enable = true;
        barbecue.enable = true;
        bufferline.enable = true;

        cmp = {
          enable = true;
          autoEnableSources = true;
          settings.sources = [
            {name = "nvim_lsp";}
            {name = "path";}
            {name = "buffer";}
          ];
        };
        cmp-nvim-lsp.enable = true;

        copilot-lua = {
          enable = true;
          settings = {
            suggestion.enabled = false;
            panel.enabled = false;
          };
        };
        copilot-cmp.enable = true;

        oil = {
          enable = true;
          settings = {
            view_options.show_hidden = true;
            keymaps = {
              "q" = "actions.close";
              "<C-s>" = "actions.select_vsplit";
            };
          };
        };

        fugitive.enable = true;
        gitblame.enable = true;
        gitsigns.enable = true;
        glow.enable = true;
        illuminate.enable = true;

        flash = {
          enable = true;
          settings.modes.search.enabled = false;
        };

        nvim-surround.enable = true;
        harpoon.enable = true;

        undotree = {
          enable = true;
          settings.FocusOnToggle = true;
        };

        numbertoggle.enable = true;

        lsp = {
          enable = true;

          inlayHints = true;

          onAttach = ''
                   if not client.supports_method("textDocument/codeLens") then
              return
            end
            local group = vim.api.nvim_create_augroup("LspCodeLens." .. bufnr, {})
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
              group = group,
              buffer = bufnr,
              callback = vim.lsp.codelens.refresh,
            })

            local diag_group = vim.api.nvim_create_augroup("LspDiagnosticsFloat." .. bufnr, {})
            vim.api.nvim_create_autocmd("CursorHold", {
              group = diag_group,
              buffer = bufnr,
              callback = function()
                local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
                if next(vim.diagnostic.get(bufnr, { lnum = lnum })) == nil then
                  return
                end
                vim.diagnostic.open_float(nil, { focus = false, scope = "line" })
              end,
            })
          '';

          servers = {
            bashls.enable = true;
            clangd.enable = true;
            cssls.enable = true;
            dockerls.enable = true;

            gopls = {
              enable = true;
              autostart = true;
            };

            html.enable = true;

            ltex = {
              enable = true;
              settings = {
                enabled = [
                  "latex"
                  "text"
                  "tex"
                  "tex"
                ];
                completionEnabled = true;
                language = "en-US";
              };
            };

            lua_ls = {
              enable = true;
              settings.telemetry.enable = false;
            };

            marksman.enable = true;
            nil_ls.enable = true;
            pyright.enable = true;

            rust_analyzer = {
              enable = true;
              installRustc = true;
              installCargo = true;
            };

            terraformls.enable = true;
            ts_ls.enable = true;
            yamlls.enable = true;
            zls.enable = true;
          };
        };

        conform-nvim = {
          enable = true;
          settings = {
            format_on_save = {
              timeout_ms = 2000;
              lsp_format = "fallback";
            };
            formatters_by_ft = {
              go = ["gofmt" "goimports"];
              python = ["isort" "black"];
              terraform = ["terraform_fmt"];
              hcl = ["hclfmt"];
              nomad = ["hclfmt"];
              yaml = ["yamlfix"];
              nix = ["alejandra"];
              lua = ["stylua"];
              "_" = ["trim_whitespace"];
            };
          };
        };

        lsp-signature.enable = true;
        lualine.enable = true;
        navic.enable = true;
        nix.enable = true;
        noice.enable = false;
        none-ls = {
          enable = true;
          sources = {
            diagnostics = {
              ansiblelint.enable = true;
              golangci_lint.enable = true;
              mypy.enable = true;
              pylint.enable = true;
              terraform_validate.enable = true;
              tfsec.enable = true;
              yamllint.enable = true;
            };
          };
        };
        nvim-autopairs.enable = true;
        sleuth.enable = true;

        treesitter = {
          enable = true;
          settings.highlight.enable = true;
        };
        treesitter-textobjects = {
          enable = true;
          settings = {
            select = {
              enable = true;
              lookahead = true;
              keymaps = {
                "af" = {query = "@function.outer";};
                "if" = {query = "@function.inner";};
                "ac" = {query = "@class.outer";};
                "ic" = {query = "@class.inner";};
                "aa" = {query = "@parameter.outer";};
                "ia" = {query = "@parameter.inner";};
                "ai" = {query = "@conditional.outer";};
                "ii" = {query = "@conditional.inner";};
                "al" = {query = "@loop.outer";};
                "il" = {query = "@loop.inner";};
              };
            };
            move = {
              enable = true;
              set_jumps = true;
              goto_next_start = {
                "]f" = "@function.outer";
                "]c" = "@class.outer";
                "]a" = "@parameter.inner";
              };
              goto_next_end = {
                "]F" = "@function.outer";
                "]C" = "@class.outer";
              };
              goto_previous_start = {
                "[f" = "@function.outer";
                "[c" = "@class.outer";
                "[a" = "@parameter.inner";
              };
              goto_previous_end = {
                "[F" = "@function.outer";
                "[C" = "@class.outer";
              };
            };
            swap = {
              enable = true;
              swap_next = {
                "<leader>sa" = "@parameter.inner";
              };
              swap_previous = {
                "<leader>sA" = "@parameter.inner";
              };
            };
          };
        };

        tmux-navigator.enable = true;

        telescope = {
          enable = true;
          extensions = {
            fzf-native.enable = true;
            file-browser.enable = true;
          };
          keymaps = {
            "<leader>f'" = {
              action = "marks";
              options.desc = "View marks";
            };
            "<leader>f/" = {
              action = "current_buffer_fuzzy_find";
              options.desc = "Fuzzy find in current buffer";
            };
            "<leader>f<CR>" = {
              action = "resume";
              options.desc = "Resume action";
            };
            "<leader>fa" = {
              action = "autocommands";
              options.desc = "View autocommands";
            };
            "<leader>fC" = {
              action = "commands";
              options.desc = "View commands";
            };
            "<leader>fb" = {
              action = "file_browser";
              options.desc = "Open File Browser";
            };
            "<leader>fB" = {
              action = "buffers";
              options.desc = "View buffers";
            };
            "<leader>fd" = {
              action = "diagnostics";
              options.desc = "View diagnostics";
            };
            "<leader>fg" = {
              action = "grep_string";
              options.desc = "Grep string";
            };
            "<leader>ff" = {
              action = "find_files";
              options.desc = "Find files";
            };
            "<leader>fh" = {
              action = "help_tags";
              options.desc = "View help tags";
            };
            "<leader>fm" = {
              action = "man_pages";
              options.desc = "View man pages";
            };
            "<leader>fo" = {
              action = "oldfiles";
              options.desc = "View old files";
            };
            "<leader>fr" = {
              action = "registers";
              options.desc = "View registers";
            };
            "<leader>fs" = {
              action = "lsp_document_symbols";
              options.desc = "Search symbols";
            };
            "<leader>fq" = {
              action = "quickfix";
              options.desc = "Search quickfix";
            };
            "<leader>gd" = {
              action = "lsp_definitions";
              options.desc = "Go to Definitions";
            };
            "<leader>gr" = {
              action = "lsp_references";
              options.desc = "List References";
            };
            "<leader>gI" = {
              action = "lsp_implementations";
              options.desc = "Go to Implementations";
            };
            "<leader>gt" = {
              action = "lsp_type_definitions";
              options.desc = "Go to Type Definitions";
            };
          };
        };

        todo-comments = {
          enable = true;
          settings.colors = {
            error = [
              "DiagnosticError"
              "ErrorMsg"
              "#DC2626"
            ];
            warning = [
              "DiagnosticWarn"
              "WarningMsg"
              "#FBBF24"
            ];
            info = [
              "DiagnosticInfo"
              "#2563EB"
            ];
            hint = [
              "DiagnosticHint"
              "#10B981"
            ];
            default = [
              "Identifier"
              "#7C3AED"
            ];
            test = [
              "Identifier"
              "#FF00FF"
            ];
          };
        };

        dap = {
          enable = true;
          extensionConfigLua = ''
            local dap_ok, dap = pcall(require, "dap")
            if dap_ok then
              local dapui_ok, dapui = pcall(require, "dapui")
              if dapui_ok then
                dap.listeners.after.event_initialized["dapui_config"] = function()
                  dapui.open()
                end
                dap.listeners.before.event_terminated["dapui_config"] = function()
                  dapui.close()
                end
                dap.listeners.before.event_exited["dapui_config"] = function()
                  dapui.close()
                end
              end
            end
          '';
        };
        dap-go.enable = true;
        dap-lldb.enable = true;
        dap-python.enable = true;
        dap-ui.enable = true;
        dap-virtual-text.enable = true;

        trouble.enable = true;
        web-devicons.enable = true;
        which-key.enable = true;
        zig.enable = true;
      };

      keymaps = [
        {
          key = "-";
          action = "<cmd>Oil<cr>";
          options.desc = "Open parent directory";
        }
        {
          key = "<leader>u";
          action = "<cmd>UndotreeToggle<cr>";
          options.desc = "Toggle undotree";
        }
        {
          key = "<leader>fl";
          action = "<cmd>Telescope live_grep<cr>";
          options.desc = "Live grep";
        }
        {
          key = "<leader>ha";
          action.__raw = "function() require'harpoon':list():add() end";
          options.desc = "Harpoon add file";
        }
        {
          key = "<leader>hh";
          action.__raw = "function() local harpoon = require'harpoon'; harpoon.ui:toggle_quick_menu(harpoon:list()) end";
          options.desc = "Harpoon menu";
        }
        {
          key = "<leader>h1";
          action.__raw = "function() require'harpoon':list():select(1) end";
          options.desc = "Harpoon file 1";
        }
        {
          key = "<leader>h2";
          action.__raw = "function() require'harpoon':list():select(2) end";
          options.desc = "Harpoon file 2";
        }
        {
          key = "<leader>h3";
          action.__raw = "function() require'harpoon':list():select(3) end";
          options.desc = "Harpoon file 3";
        }
        {
          key = "<leader>h4";
          action.__raw = "function() require'harpoon':list():select(4) end";
          options.desc = "Harpoon file 4";
        }
      ];
    };
  };
}

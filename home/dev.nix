{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  home.packages = with pkgs; [
    claude-code
    crush
    delta
    devenv
    fzf
    gh
    git
    gnupg
    hack-font
    lazygit
    mosh
    nix-output-monitor
    opencode
    ripgrep
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    gpg = {
      enable = true;
      publicKeys = [ ];
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

      settings = {
        user = {
          name = "Ananth Bhaskararaman";
          email = "antsub@gmail.com";
          useConfigOnly = "true";
        };

        core.editor = "nvim";
        core.pager = "delta";
        init.defaultBranch = "main";

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
      };

      globals.mapleader = " ";

      colorschemes.oxocarbon.enable = true;

      plugins = {
        aw-watcher.enable = true;
        barbecue.enable = true;
        bufferline.enable = true;
        copilot-vim.enable = true;

        cmp = {
          enable = true;
          autoEnableSources = true;
          settings.sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
        };
        cmp-nvim-lsp.enable = true;

        fugitive.enable = true;
        gitblame.enable = true;
        gitsigns.enable = true;
        glow.enable = true;
        illuminate.enable = true;
        leap.enable = true;
        numbertoggle.enable = true;

        # Language server
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

            # Rust
            rust_analyzer = {
              enable = true;
              installRustc = true;
              installCargo = true;
            };

            ts_ls.enable = true;
            yamlls.enable = true;
            zls.enable = true;
          };
        };

        lsp-format.enable = true;
        lsp-signature.enable = true;
        lualine.enable = true;
        navic.enable = true;
        nix.enable = true;
        noice.enable = false;
        none-ls.enable = true;
        nvim-autopairs.enable = true;
        sleuth.enable = true;

        # Good old Telescope
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

        # Todo comments
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

        trouble.enable = true;
        treesitter.enable = true;
        web-devicons.enable = true;
        which-key.enable = true;
        zig.enable = true;
      };
    };
  };

  sops.secrets."Yubico/u2f_keys" = {
    path = config.xdg.configHome + "/Yubico/u2f_keys";
  };
}

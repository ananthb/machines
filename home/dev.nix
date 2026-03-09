{
  config,
  inputs,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  askpass = pkgs.stdenv.mkDerivation {
    name = "askpass";
    src = ../lib/askpass.sh;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/askpass.sh
      chmod +x $out/bin/askpass.sh
    '';
  };
in {
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  sops = {
    age.sshKeyPaths = [(homeDir + "/.ssh/id_ed25519")];
    defaultSopsFile = ../secrets/dev.yaml;

    secrets = {
      "ssh/yubikey_5c" = {
        path = homeDir + "/.ssh/yubikey_5c";
      };
      "ssh/yubikey_5c.pub" = {
        path = homeDir + "/.ssh/yubikey_5c.pub";
      };
      "ssh/yubikey_5c_nano" = {
        path = homeDir + "/.ssh/yubikey_5c_nano";
      };
      "ssh/yubikey_5c_nano.pub" = {
        path = homeDir + "/.ssh/yubikey_5c_nano.pub";
      };
    };
  };

  # Fix for sops-nix LaunchAgent on macOS.
  launchd.agents.sops-nix = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      EnvironmentVariables = {
        PATH = pkgs.lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };

  home.packages = with pkgs;
    [
      coder
      codex
      delta
      devenv
      flyctl
      fzf
      gemini-cli
      gh
      git
      gnupg
      hack-font
      lazygit
      mosh
      nix-output-monitor
      ripgrep
      vault
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [askpass];

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
        updatetime = 300;
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
        copilot-vim.enable = true;

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

            # Rust
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

        lsp-format.enable = true;
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
            formatting = {
              black.enable = true;
              gofmt.enable = true;
              goimports.enable = true;
              hclfmt = {
                enable = true;
                settings.extra_filetypes = ["nomad"];
              };
              isort.enable = true;
              terraform_fmt.enable = true;
              yamlfix.enable = true;
            };
          };
        };
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
        treesitter.enable = true;
        web-devicons.enable = true;
        which-key.enable = true;
        zig.enable = true;
      };
    };
  };
}

{ self, inputs, lib, ... }:
{
  perSystem = { pkgs, ... }:
  let
    # Nixvim-configured Neovim, then wrapped (vim alias + LSP servers on PATH).
    neovim = inputs.nixvim.legacyPackages.${pkgs.system}.makeNixvim {
  
  # --- LSP --- #

  lsp.servers.zls = {
    enable = true;
    config = {
      cmd = [ "zls" ];
      filetypes = [ "zig" ];
      root_markers = [ "build.zig" ".git" ];
      # Attach zls even for single .zig files outside a project (no build.zig/.git).
      workspace_required = false;
    };
  };

  lsp.servers.cssls = {
    enable = true;
    config = {
      cmd = [ "vscode-css-language-server" "--stdio" ];
      filetypes = [ "css" "scss" "less" ];
      root_markers = [ ".git" ];
    };
  };

  lsp.servers.rust_analyzer = {
    enable = true;
    config = {
      cmd = ["rust-analyzer"];
      filetypes = [ "rust" ];
      root_markers = ["Cargo.toml"];
    };
  };

  lsp.servers.gleam = {
    enable = true;
    config = {
      cmd = [ "gleam" "lsp" ];
      filetypes = [ "gleam" ];
      root_markers = [ "gleam.toml" ];
    };
  };

  lsp.servers.nixd = {
    enable = true;
    config = {
      cmd = [ "nixd" ];
      filetypes = [ "nix" ];
      root_markers = [ "flake.nix" "default.nix" ".git" ];
    };
  };

  lsp.servers.yamlls = {
    enable = true;
    config = {
      cmd = [ "yaml-language-server" "--stdio" ];
      filetypes = [ "yaml" "yml" ];
      root_markers = [ ".git" ];
    };
  };

  # --- Diagnostics --- #
  diagnostic.settings = {
    virtual_text = true; # show the error message inline
    signs = true;        # show icons in the sign column
    update_in_insert = false;
    severity_sort = true;
    float = {
      border = "rounded";
    };
  };

  globals = {
    mapleader = " ";
  };

  extraConfigLua = ''
    _G.FileHistory = {
      history = {},
      index = 0,
    }

    function _G.FileHistory.record()
      local file = vim.api.nvim_buf_get_name(0)
      if file == "" then return end
      local cwd = vim.loop.cwd()
      if not vim.startswith(file, cwd) then return end
      if _G.FileHistory.history[_G.FileHistory.index] == file then return end
      for i = #_G.FileHistory.history, _G.FileHistory.index + 1, -1 do
        _G.FileHistory.history[i] = nil
      end
      table.insert(_G.FileHistory.history, file)
      _G.FileHistory.index = #_G.FileHistory.history
    end

    function _G.FileHistory.back()
      if _G.FileHistory.index > 1 then
        _G.FileHistory.index = _G.FileHistory.index - 1
        vim.cmd("edit " .. vim.fn.fnameescape(_G.FileHistory.history[_G.FileHistory.index]))
      end
    end

    function _G.FileHistory.forward()
      if _G.FileHistory.index < #_G.FileHistory.history then
        _G.FileHistory.index = _G.FileHistory.index + 1
        vim.cmd("edit " .. vim.fn.fnameescape(_G.FileHistory.history[_G.FileHistory.index]))
      end
    end
  '';

  plugins.markview = {
    enable = true;
  };

  plugins.mini = {
    modules = {
      pairs = {};
      icons = {};
      comment = {};
    };
  };

  plugins.oil = {
    enable = true;
    settings = {
      skip_confirm_for_simple_edits = true;
    };
  };

  plugins.harpoon = {
    enable = true;
  };

  plugins.telescope = {
    enable = true;
    settings = {
      defaults = {
        file_ignore_patterns = [
          "build/"
          "dist/"
          "node_modules/"
          ".devenv/"
          "%.lock"
        ];
      };
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<CR>";
      options = {
        desc = "Find files";
      };
    }
    {
      mode = "n";
      key = "<leader>fr";
      action = {
        __raw = ''
          function()
            require("telescope.builtin").oldfiles({ cwd_only = true })
          end
        '';
      };
      options = {
        desc = "Recent files (cwd)";
      };
    }
    {
      mode = "n";
      key = "<leader>fg";
      action = "<cmd>Telescope grep_string<CR>";
      options = {
        desc = "Grep string";
      };
    }
    {
      mode = "n";
      key = "<leader>fd";
      action = "<cmd>Telescope diagnostics<CR>";
      options = {
        desc = "List diagnostics";
      };
    }
    {
      mode = "n";
      key = "<leader>fs";
      action = {
        __raw = ''
          function()
            local bufnr = vim.api.nvim_get_current_buf()
            local params = vim.lsp.util.make_position_params()
            vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result)
              if err or not result or vim.tbl_isempty(result) then
                vim.notify("No symbols found", vim.log.levels.INFO)
                return
              end
              require("telescope.builtin").lsp_document_symbols()
            end)
          end
        '';
      };
      options = {
        desc = "Document symbols";
      };
    }
    {
      mode = "n";
      key = "<leader>a";
      action = {
        __raw = ''
          function()
            local list = require("harpoon"):list()
            local Path = require("plenary.path")
            local file = Path:new(vim.api.nvim_buf_get_name(0)):make_relative(vim.loop.cwd())
            if list:get_by_value(file) then
              list:remove()
              vim.notify("Harpoon: unmarked " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
            else
              list:add()
              vim.notify("Harpoon: marked " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
            end
          end
        '';
      };
      options = {
        desc = "Toggle file in harpoon";
      };
    }
    {
      mode = "n";
      key = "<C-e>";
      action = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<CR>";
      options = {
        desc = "Toggle harpoon menu";
      };
    }
    {
      mode = "n";
      key = "<leader>1";
      action = "<cmd>lua require('harpoon'):list():select(1)<CR>";
      options = {
        desc = "Harpoon slot 1";
      };
    }
    {
      mode = "n";
      key = "<leader>2";
      action = "<cmd>lua require('harpoon'):list():select(2)<CR>";
      options = {
        desc = "Harpoon slot 2";
      };
    }
    {
      mode = "n";
      key = "<leader>3";
      action = "<cmd>lua require('harpoon'):list():select(3)<CR>";
      options = {
        desc = "Harpoon slot 3";
      };
    }
    {
      mode = "n";
      key = "<leader>4";
      action = "<cmd>lua require('harpoon'):list():select(4)<CR>";
      options = {
        desc = "Harpoon slot 4";
      };
    }
    {
      mode = "n";
      key = "<leader>w";
      action = "<cmd>write<CR>";
      options = {
        desc = "Write file";
      };
    }
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Oil<CR>";
      options = {
        desc = "Open oil (file manager)";
      };
    }
    {
      mode = "n";
      key = "<leader>t";
      action = {
        __raw = ''
          function()
            local file = vim.loop.cwd() .. "/TODO.md"
            vim.cmd("edit " .. vim.fn.fnameescape(file))
          end
        '';
      };
      options = {
        desc = "Open project TODO.md";
      };
    }
    {
      mode = "x";
      key = "gc";
      action = {
        __raw = ''
          function()
            local s = vim.fn.getpos("'<")[2]
            local e = vim.fn.getpos("'>")[2]
            require("mini.comment").toggle_lines(s, e)
            vim.cmd("normal! gv")
          end
        '';
      };
      options = {
        desc = "Toggle comment (stay in visual)";
      };
    }
    {
      mode = "n";
      key = "<leader>q";
      action = "<cmd>quit<CR>";
      options = {
        desc = "Quit window";
      };
    }
    {
      mode = "n";
      key = "<C-j>";
      action = {
        __raw = "function() _G.FileHistory.back() end";
      };
      options = {
        desc = "File history: back";
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action = {
        __raw = "function() _G.FileHistory.forward() end";
      };
      options = {
        desc = "File history: forward";
      };
    }
  ];

  plugins.blink-cmp = {
    enable = true;
    settings = {
      keymap = {
        preset = "default";
        "<C-j>" = [ "select_next" "snippet_forward" ];
        "<C-k>" = [ "select_prev" "snippet_backward" ];
        "<CR>" = [ "accept" "fallback" ];
      };
      appearance.nerd_font_variant = "mono";
      sources = {
        default = [ "lsp" "path" "buffer" ];
      };
    };
  };

  opts = {
    number = true;
    relativenumber = true;

    wrap = true;
    undofile = true;

    ignorecase = true;
    smartcase = true;
    hlsearch = false;

    expandtab = true;
    softtabstop = 2;
    tabstop = 2;
    shiftwidth = 2;
    autoindent = true;
    copyindent = true;
    breakindent = true;

    cursorline = true;
    list = true;
    listchars = {
      tab = "»·";
      trail = "·";
      nbsp = "␣";
    };
    scrolloff = 10;
    confirm = true;
    signcolumn = "yes";

    mouse = "a";
    clipboard = "unnamedplus";

    updatetime = 500;
    timeoutlen = 500;
  };

  autoGroups = {
    highlight_group = {
      clear = true;
    };
    format_on_save = {
      clear = true;
    };
    harpoon_menu = {
      clear = true;
    };
    file_history = {
      clear = true;
    };
    markdown_todo = {
      clear = true;
    };
    makefile = {
      clear = true;
    };
  };

  autoCmd = [
    {
      desc = "Highlight yanked text";
      event = ["TextYankPost"];
      pattern = "*";
      callback = {
        __raw = "function() vim.highlight.on_yank() end";
      };
      group = "highlight_group";
    }
    {
      desc = "Format on save using any attached LSP that supports formatting";
      event = ["BufWritePre"];
      pattern = "*.*";
      callback = {
        __raw = ''
          function(args)
            local clients = vim.lsp.get_clients({ bufnr = args.buf, supports_method = "textDocument/formatting" })
            if #clients == 0 then return end
            vim.lsp.buf.format({ bufnr = args.buf })
          end
        '';
      };
      group = "format_on_save";
    }
    {
      desc = "Harpoon menu: delete / move items";
      event = ["FileType"];
      pattern = "harpoon";
      callback = {
        __raw = ''
          function(args)
            local bufnr = args.buf
            local function current()
              local list = require("harpoon"):list()
              local line = vim.api.nvim_get_current_line()
              local item, idx = list:get_by_value(line)
              return list, item, idx
            end
            local function refresh()
              local list = require("harpoon"):list()
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, list:display())
            end
            vim.keymap.set("n", "dd", function()
              local list, item, idx = current()
              if item then
                list:remove_at(idx)
                require("harpoon"):sync()
                refresh()
                vim.notify("Harpoon: removed " .. vim.fn.fnamemodify(vim.api.nvim_get_current_line(), ":t"), vim.log.levels.INFO)
              end
            end, { buffer = bufnr })
            vim.keymap.set("n", "K", function()
              local list, item, idx = current()
              if not item or idx <= 1 then return end
              local items = list.items
              items[idx], items[idx - 1] = items[idx - 1], items[idx]
              require("harpoon"):sync()
              refresh()
            end, { buffer = bufnr })
            vim.keymap.set("n", "J", function()
              local list, item, idx = current()
              if not item or idx >= list:length() then return end
              local items = list.items
              items[idx], items[idx + 1] = items[idx + 1], items[idx]
              require("harpoon"):sync()
              refresh()
            end, { buffer = bufnr })
          end
        '';
      };
      group = "harpoon_menu";
    }
    {
      desc = "Record file history";
      event = ["BufEnter"];
      pattern = "*";
      callback = {
        __raw = "function() _G.FileHistory.record() end";
      };
      group = "file_history";
    }
    {
      desc = "Markdown checkbox toggle";
      event = ["FileType"];
      pattern = "markdown";
      callback = {
        __raw = ''
          function(args)
            local bufnr = args.buf
            local MiniPairs = require("mini.pairs")
            MiniPairs.map_buf(bufnr, "i", "*", {
              action = "closeopen",
              pair = "**",
              neigh_pattern = "[^%w].*",
            })
            MiniPairs.map_buf(bufnr, "i", "_", {
              action = "closeopen",
              pair = "__",
              neigh_pattern = "[^%w].*",
            })
            vim.keymap.set("n", "<leader>x", function()
              local line = vim.api.nvim_get_current_line()
              if line:match("^%s*- %[ %]") then
                line = line:gsub("%- %[ %]", "- [x]", 1)
              elseif line:match("^%s*- %[x%]") then
                line = line:gsub("%- %[x%]", "- [ ]", 1)
              end
              vim.api.nvim_set_current_line(line)
            end, { buffer = bufnr })
            vim.keymap.set("i", "<CR>", function()
              local line = vim.api.nvim_get_current_line()
              local prefix = line:match("^(%s*>%s?)")
              if prefix then
                return "\n" .. prefix
              end
              return "\n"
            end, { buffer = bufnr, expr = true })
          end
        '';
      };
      group = "markdown_todo";
    }
    {
      desc = "Makefile: use real tabs";
      event = ["FileType"];
      pattern = "make";
      callback = {
        __raw = "function() vim.bo.expandtab = false end";
      };
      group = "makefile";
    }
  ];
    };
  in {
    packages.nvim = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = neovim;
      aliases = [ "vim" ];
      runtimeInputs = with pkgs; [
        zls
        rust-analyzer
        nixd
        gleam
        vscode-langservers-extracted
        yaml-language-server
      ];
    };
  };
}

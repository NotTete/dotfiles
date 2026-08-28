{ self, inputs, lib, ... }:
{
  perSystem = { pkgs, ... }:
  let
    # rose-pine palette (from the old stylix setup, hardcoded here)
    iris = "#c4a7e7"; # user / arrow
    foam = "#9ccfd8"; # host
    gold = "#f6c177"; # cwd
    love = "#eb6f92"; # error arrow
    muted = "#6e6a86"; # @ separator, git branch
  in {
    # Wrap zsh with the config baked in via ZDOTDIR (.zshrc / .zshenv).
    packages.zsh = (inputs.wrappers.wrapperModules.zsh.apply {
      inherit pkgs;

      settings = {
        autocd = true;

        shellAliases = {
          ls = "eza  --icons auto -T -L=2";
          ll = "eza --icons auto -la -T -L=2";
          update = "sudo nixos-rebuild switch --flake ~/dotfiles2";
        };

        history = {
          size = 10000;
          file = "$HOME/.zsh_history";
          ignoreAllDups = true;
        };

        completion.enable = true;
        autoSuggestions.enable = true;

        integrations.fzf.enable = true;

        env = { };
      };

      extraPackages = with pkgs; [
        eza
        zsh-syntax-highlighting
      ];

      # zsh-syntax-highlighting + the fish-style two-line prompt (rose-pine).
      extraRC = ''
        # syntax highlighting
        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        # ── fish-style two-line prompt ────────────────────────────────────
        #   user@host ~/path  <git-branch>
        #   ❯
        # `❯` turns red (love) when the last command exited non-zero.
        setopt PROMPT_SUBST

        _pi_prompt() {
          local rc=$?            # capture before anything resets it
          # line 1: user@host  cwd  (git branch)
          print -n "%F{${iris}}%n%f%F{${muted}}@%f%F{${foam}}%m%f %F{${gold}}%~%f"
          local branch
          branch=$(git -C "$PWD" symbolic-ref --short HEAD 2>/dev/null \
                   || git -C "$PWD" rev-parse --short HEAD 2>/dev/null)
          [[ -n $branch ]] && print -n " %F{${muted}}$branch%f"
          print
          # line 2: arrow (iris when ok, love on error)
          if [[ $rc -eq 0 ]]; then
            print -n "%F{${iris}}❯%f "
          else
            print -n "%F{${love}}❯%f "
          fi
        }

        PROMPT='$(_pi_prompt)'
        RPROMPT="" # keep it clean, like fish
      '';
    }).wrapper;
  };
}

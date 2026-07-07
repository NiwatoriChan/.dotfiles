# Home Manager Configuration

This page outlines the user-level configuration managed via Home Manager in the `home/` folder. Home Manager handles personal package management, user environments, git credentials, shell configs, and desktop theming.

---

## 📂 Structure & Profile Baseline

In `home/common/default.nix`, the user environment is defined for username `niwatorichan` targeting `/home/niwatorichan`:

- **Home Manager**: Enabled to manage itself (`programs.home-manager.enable = true`).
- **State Version**: Set to `26.05`.
- **Modularity**: Imports git, shell, and user packages.

---

## 🐚 Zsh & Powerlevel10k Setup

Defined in `home/common/shell.nix`, the shell config is a modern, fully-featured Zsh environment:

### Features & Addons
- **Completion**: Enabled natively (`enableCompletion = true`).
- **Autosuggestions**: Enabled (`autosuggestion.enable = true`) to show commands as you type.
- **Syntax Highlighting**: Enabled (`syntaxHighlighting.enable = true`) to colorize commands.
- **History Tuning**: Keeps up to 10,000 entries, saving to `~/.zsh_history` while ignoring all sequential duplicates.

### 🎨 Powerlevel10k Theme
The interactive Powerlevel10k prompt is integrated directly via the Nix package manager:
- Package: `pkgs.zsh-powerlevel10k`
- Configuration: Sourced dynamically from `./home/common/p10k.zsh` mapped to `~/.p10k.zsh`.

### ⌨️ Shell Aliases
Quick-command aliases are defined to speed up common tasks:
```zsh
alias ll="ls -l"                      # Long listing format
alias edit="sudo -e"                  # Securely edit files as root
alias update="sudo nixos-rebuild switch"  # Rebuild the NixOS configuration
```

---

## 🐙 Git Configuration

Defined in `home/common/git.nix`, global Git variables are declared cleanly:

```nix
programs.git = {
  enable = true;
  settings = {
    user = {
      name = "niwatorichan";
      email = "charloslivro2@gmail.com";
    };
    init.defaultBranch = "main";
    pull.rebase = true;
  };
};
```

- **Rebase Pulls**: Configured by default (`pull.rebase = true`) to keep git history linear.
- **Default Branch**: Set to `main` for new repositories.

---

## 📦 User Packages

Located in `home/common/packages.nix`, this file provides an empty slot for user-level packages. 
> [!TIP]
> Use this file to install CLI utilities or user-specific graphical apps that you want isolated to your user account without modifying the system-level packages in `/hosts/common/packages.nix`.

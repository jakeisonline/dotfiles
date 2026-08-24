# Dotfiles

macOS setup managed with [Homebrew Bundle](https://docs.brew.sh/Manpage#bundle-subcommand) and [GNU Stow](https://www.gnu.org/software/stow/).

## Fresh machine

```bash
git clone <repo-url> ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

Pass `--macos` to also apply `macos/.macos` defaults (requires sudo).

`bootstrap.sh` will:

1. Install Xcode Command Line Tools (needed for Homebrew/git)
2. Install/update Homebrew
3. Install packages from `homebrew/Brewfile` (includes full Xcode via the App Store)
4. Stow `zsh` and `git` into `$HOME`
5. Install oh-my-zsh + fzf-tab (without clobbering the stowed `.zshrc`)

## Layout

| Path | Role |
| --- | --- |
| `bootstrap.sh` | One-shot installer |
| `homebrew/Brewfile` | Source of truth for formulae, casks, and Mac App Store apps |
| `zsh/`, `git/` | Stow packages → `~/.zshrc`, `~/.gitconfig`, etc. |
| `macos/.macos` | Optional macOS defaults |

## Day to day

Edit `homebrew/Brewfile`, then:

```bash
brew bundle --file=~/.dotfiles/homebrew/Brewfile
```

After changing stow packages:

```bash
cd ~/.dotfiles && stow --restow --target="$HOME" zsh git
```

And don't forget to commit and push!

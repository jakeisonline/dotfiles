#!/usr/bin/env bash
# git clone <repo> ~/.dotfiles && ~/.dotfiles/bootstrap.sh
# Optional: ~/.dotfiles/bootstrap.sh --macos

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
APPLY_MACOS=0

for arg in "$@"; do
  case "$arg" in
    --macos) APPLY_MACOS=1 ;;
    -h|--help)
      echo "Usage: $0 [--macos]"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    echo "Xcode Command Line Tools already installed; skipping."
    return
  fi

  echo "Installing Xcode Command Line Tools..."
  # Prefer the non-interactive softwareupdate path when available.
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  local label
  label="$(
    softwareupdate -l 2>/dev/null \
      | awk -F'*' '/Command Line Tools/ {print $2}' \
      | sed -e 's/^ *Label: //' -e 's/^ *//' \
      | sort -V \
      | tail -n1
  )"

  if [[ -n "$label" ]]; then
    softwareupdate -i "$label" --verbose
  else
    xcode-select --install
    echo "Waiting for Command Line Tools install to finish..."
    until xcode-select -p >/dev/null 2>&1; do
      sleep 5
    done
  fi

  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
}

select_xcode_app() {
  if [[ ! -d /Applications/Xcode.app ]]; then
    return
  fi

  echo "Selecting Xcode.app as the active developer directory..."
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -license accept >/dev/null 2>&1 || true
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew already installed; updating..."
    brew update
    return
  fi

  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Homebrew installed but brew not found on PATH." >&2
    exit 1
  fi
}

ensure_oh_my_zsh() {
  if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    echo "Installing oh-my-zsh..."
    # Don't launch zsh or touch a stowed ~/.zshrc.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "oh-my-zsh already installed; skipping."
  fi

  local fzf_tab="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/fzf-tab"
  if [[ ! -d "$fzf_tab" ]]; then
    echo "Installing fzf-tab..."
    git clone https://github.com/Aloxaf/fzf-tab "$fzf_tab"
  else
    echo "fzf-tab already installed; skipping."
  fi
}

stow_packages() {
  echo "Stowing packages into \$HOME..."
  # Stow from repo root so package dirs (zsh/, git/) map to ~/
  (
    cd "$DOTFILES"
    stow --restow --target="$HOME" zsh git
  )
}

echo "==> Ensuring Xcode Command Line Tools"
ensure_xcode_clt

echo "==> Ensuring Homebrew"
ensure_homebrew

echo "==> Installing Brewfile packages"
brew bundle --file="${DOTFILES}/homebrew/Brewfile"

echo "==> Pointing xcode-select at Xcode.app (if present)"
select_xcode_app

echo "==> Linking configs with Stow"
stow_packages

echo "==> Ensuring oh-my-zsh + fzf-tab"
ensure_oh_my_zsh

if [[ "$APPLY_MACOS" -eq 1 ]]; then
  echo "==> Applying macOS defaults"
  # shellcheck source=/dev/null
  source "${DOTFILES}/macos/.macos"
else
  echo "==> Skipping macOS defaults (pass --macos to apply)"
fi

echo "Done. Open a new terminal (or exec zsh) to pick up the shell config."

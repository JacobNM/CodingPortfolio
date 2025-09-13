# Get Zsh + Spaceship Prompt Working

This README walks you from zero → a slick Zsh prompt using Spaceship.

⸻

## 1) Install Zsh

### macOS
```
# Zsh ships with macOS. Ensure it's present and set as default shell:
zsh --version
which zsh
chsh -s "$(which zsh)"
```
### Ubuntu/Debian
```
sudo apt update
sudo apt install -y zsh git
chsh -s "$(which zsh)"
```
### Fedora
```
sudo dnf install -y zsh git
chsh -s "$(which zsh)"
```
### Windows (WSL)
	1.	Install a WSL distro (e.g., Ubuntu) from the Microsoft Store.
	2.	Open the distro and run the Ubuntu commands above.
	3.	Use a terminal with Nerd Font support (see Fonts below).

Log out/in or restart your terminal after chsh so the change takes effect.

⸻

## 2) (Optional but Recommended) Install a Nerd Font

Spaceship looks best with a Nerd Font.
	•	macOS (Homebrew):
```
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
```

•	Manual: Download a Nerd Font from https://www.nerdfonts.com/ and set it in your terminal profile.

Then set your terminal to use the Nerd Font you installed.

⸻

## 3) Install Spaceship Prompt (no framework)

We’ll use a simple git clone + source approach so this works the same on any OS, without Oh-My-Zsh or plugin managers.
```
# Create a folder for custom Zsh stuff
mkdir -p "$HOME/.zsh"

# Clone Spaceship Prompt
git clone https://github.com/spaceship-prompt/spaceship-prompt.git \
  "$HOME/.zsh/spaceship-prompt" --depth=1
```

⸻

## 4) Create/Update your ~/.zshrc

Paste the entire block below into ~/.zshrc (replace everything if you’re starting fresh).
This gives you a solid default Spaceship setup that’s fast and readable.
```
# ---------------------------
# ~/.zshrc — Zsh + Spaceship
# ---------------------------

# 1) Basic Zsh setup
export ZDOTDIR="$HOME"
export EDITOR="vim"

# Better history
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY EXTENDED_HISTORY SHARE_HISTORY

# Sensible completion
autoload -Uz compinit
zmodload zsh/complist
compinit -d "$HOME/.zcompdump"
setopt AUTO_LIST AUTO_MENU COMPLETE_IN_WORD
zstyle ':completion:*' menu select

# Prompt should refresh on each command
setopt PROMPT_SUBST

# 2) Spaceship Prompt — must be sourced AFTER any SPACESHIP_* config
#    (Install with: git clone https://github.com/spaceship-prompt/spaceship-prompt.git ~/.zsh/spaceship-prompt --depth=1)

# --- Spaceship configuration (set BEFORE 'source spaceship.zsh') ---
# Order of sections (tweak to taste). Comment items to hide them.
SPACESHIP_PROMPT_ORDER=(
  time          # current time
  user          # username
  host          # hostname
  dir           # current directory
  git           # git status
  node          # Node.js
  python        # Python venv
  ruby          # Ruby
  golang        # Go
  rust          # Rust
  docker        # Docker context
  aws           # AWS profile
  azure         # Azure subscription
  gcloud        # GCP project
  package       # package version (npm, pip, etc.)
  exec_time     # command execution time
  line_sep      # line break
  battery       # battery level
  vi_mode       # vi mode
  jobs          # background jobs
  exit_code     # exit code of last command
  char          # prompt symbol
)

# Prompt symbol on the last line
SPACESHIP_PROMPT_ADD_NEWLINE="true"

# Trim path intelligently
SPACESHIP_DIR_TRUNC_REPO="true"
SPACESHIP_DIR_TRUNC="3"

# Show Python venv name (instead of path)
SPACESHIP_PYTHON_SHOW_VENV="true"
SPACESHIP_PYTHON_SYMBOL="🐍 "

# Friendlier git symbols
SPACESHIP_GIT_SYMBOL=" "
SPACESHIP_GIT_BRANCH_COLOR="blue"

# Make long-running commands obvious (>5s)
SPACESHIP_EXEC_TIME_THRESHOLD="5"

# Clean, compatible character
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_COLOR_SUCCESS="green"
SPACESHIP_CHAR_COLOR_FAILURE="red"

# Optional: time segment
SPACESHIP_TIME_SHOW="false"  # set "true" to show

# Optional: Azure segment tweaks (example)
# SPACESHIP_AZURE_SHOW="true"
# SPACESHIP_AZURE_SYMBOL="☁︎ "

# 3) Source Spaceship
if [ -f "$HOME/.zsh/spaceship-prompt/spaceship.zsh" ]; then
  source "$HOME/.zsh/spaceship-prompt/spaceship.zsh"
else
  echo "⚠️  Spaceship not found at ~/.zsh/spaceship-prompt. Did you clone it?"
fi

# 4) Useful aliases (optional)
alias ll='ls -lah'
alias gs='git status -sb'
alias gd='git diff'
alias v='${VISUAL:-$EDITOR}'
```
Tip: Every SPACESHIP_* variable must be defined before source spaceship.zsh. If you change settings, restart the shell or run exec zsh.

⸻

## 5) Test It

Open a new terminal (or run exec zsh) and you should see a multi-line prompt.
Try these to see segments appear:
```
# Git segment
git init test-spaceship && cd test-spaceship && touch a && git add a

# Python venv segment
python3 -m venv .venv && source .venv/bin/activate

# Node segment
node -v >/dev/null 2>&1 || echo "Install Node to see node segment"
```
## 6) Updates & Maintenance
```
# Update Spaceship to latest
cd "$HOME/.zsh/spaceship" && git pull --ff-only
```
## 7) Uninstall / Disable
```
# Remove sourcing from ~/.zshrc (comment out the 'source' line)
# Then optionally delete the clone:
rm -rf "$HOME/.zsh/spaceship-prompt"
```
⸻

## 8) Troubleshooting
	•	Prompt didn’t change: Ensure zsh is your login shell (echo $SHELL) and restart the terminal.
	•	Weird icons: Set your terminal font to a Nerd Font you installed.
	•	Segments missing: That language/tool may not be installed or active (e.g., Python venv).
	•	Slow prompt in huge repos: Reduce SPACESHIP_PROMPT_ORDER and disable unneeded segments.
	•	Config not applying: Confirm your SPACESHIP_* vars are above the source line in ~/.zshrc.

⸻

## 9) Bonus: Oh-My-Zsh (Alternative)

If you already use Oh-My-Zsh:
```
# Install Spaceship as an OMZ theme
git clone https://github.com/spaceship-prompt/spaceship-prompt.git \
  "$ZSH/custom/themes/spaceship-prompt" --depth=1
ln -sf "$ZSH/custom/themes/spaceship-prompt/spaceship.zsh-theme" \
  "$ZSH/custom/themes/spaceship.zsh-theme"

# In ~/.zshrc set:
# ZSH_THEME="spaceship"
# (Put your SPACESHIP_* variables ABOVE 'source $ZSH/oh-my-zsh.sh')
```

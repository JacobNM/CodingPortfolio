# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="spaceship"
# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Determines the order of sections in the Spaceship prompt.
# The order of the elements in the array defines the order of the sections.
  SPACESHIP_PROMPT_ORDER=(
    time           # Time stamps section
    user           # Username section
    dir            # Current directory section
    host           # Hostname section
    git            # Git section (git_branch + git_status + [git_commit](default off))
    hg             # Mercurial section (hg_branch  + hg_status)
    package        # Package version
    node           # Node.js section
    bun            # Bun section
    deno           # Deno section
    ruby           # Ruby section
    python         # Python section
    red            # Red section
    elm            # Elm section
    elixir         # Elixir section
    xcode          # Xcode section
    swift          # Swift section
    golang         # Go section
    perl           # Perl section
    php            # PHP section
    rust           # Rust section
    haskell        # Haskell Stack section
    scala          # Scala section
    kotlin         # Kotlin section
    java           # Java section
    lua            # Lua section
    dart           # Dart section
    julia          # Julia section
    crystal        # Crystal section
    docker         # Docker section
    docker_compose # Docker section
    aws            # Amazon Web Services section
    gcloud         # Google Cloud Platform section
    venv           # virtualenv section
    ansible        # Ansible section
    azure          # Azure section
    conda          # conda virtualenv section
    dotnet         # .NET section
    ocaml          # OCaml section
    vlang          # V section
    zig            # Zig section
    purescript     # PureScript section
    erlang         # Erlang section
    kubectl        # Kubectl context section
    terraform      # Terraform workspace section
    pulumi         # Pulumi stack section
    ibmcloud       # IBM Cloud section
    nix_shell      # Nix shell
    gnu_screen     # GNU Screen section
    exec_time      # Execution time
    async          # Async jobs indicator
    line_sep       # Line break
    battery        # Battery level and status
    jobs           # Background jobs indicator
    exit_code      # Exit code section
    sudo           # Sudo indicator
    char           # Prompt character
  )

# Customize the prefix used in venv section of the Spaceship prompt
SPACESHIP_VENV_PREFIX="venv 🤖 "

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export VANTAGE_INSTALL_POST_MERGE=true
export VANTAGE_INSTALL_POST_CHECKOUT=true

# Personal Custom  Aliases

## Add ssh Aliases
alias add_my_rsa_ssh="ssh-add ~/.ssh/id_rsa"
alias add_my_ed25519_ssh="ssh-add ~/.ssh/id_ed25519"

## ssh signin aliases
alias prodscheduler='~/vdev/internal-services/cert-based-ssh-access/connect_prod.sh'

## Add git Aliases
alias g="git"
alias gp="git pull"
alias gch="git checkout"
alias gcm="git checkout master"
alias gcb="git checkout -b"
alias gpom="git pull origin master"
alias gl="git log -5"
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gps="git push"
alias gpsom="git push origin master"
alias gst="git stash"
alias gsta="git stash apply"
alias gstp="git stash pop"
alias gcl="git clone"

export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
eval "$(/opt/homebrew/bin/brew shellenv)"
source ~/.config/op/plugins.sh

# Python Interpreter
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

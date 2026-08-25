# Development environment setup
$env.adb = "/opt/homebrew/opt/android-platform-tools/platform-tools"

# Homebrew location can be /opt/homebrew (Apple Silicon) or /usr/local (Intel).
let brew_path = (which brew | get 0?.path)
if ($brew_path == null) {
    if ("/opt/homebrew/bin/brew" | path exists) {
        $env.BREW = "/opt/homebrew/bin"
    } else if ("/usr/local/bin/brew" | path exists) {
        $env.BREW = "/usr/local/bin"
    } else {
        $env.BREW = ""
    }
} else {
    $env.BREW = ($brew_path | path dirname)
}

let brew_prefix = if ($env.BREW == "") { "" } else { ($env.BREW | path dirname) }

$env.CARGO = $"($env.HOME)/.cargo/bin"
$env.DOTNET_ROOT = $"($env.HOME)/.dotnet"
$env.DOTNET_ENV = $"($env.DOTNET_ROOT)/tools"
$env.JAVA_HOME = (try {
    ls ($brew_prefix | path join "Cellar" "openjdk" "*" "libexec" "openjdk.jdk" "Contents" "Home")
    | get 0
    | get name
} catch {
    ""
})

$env.MAVEN_HOME = ($brew_prefix | path join "opt" "maven")
$env.NVM_DIR = $"($env.HOME)/.nvm"
$env.PIPX_BIN_DIR = $"($env.HOME)/.local/bin"
$env.PNPM_HOME = $"($env.HOME)/Library/pnpm"
$env.RUSTUP = ($brew_prefix | path join "opt" "rustup")

$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"
$env.CARAPACE_LOG = 0
$env.CARAPACE_TOOLTIP = 1
$env.DOTNET_CLI_TELEMETRY_OPTOUT = 1

# Help Carapace's zsh bridge find Homebrew-installed zsh completion files (_kubectl, _helm, etc).
let brew_zsh_site = ($brew_prefix | path join "share" "zsh" "site-functions")
if ($brew_prefix != "") and ($brew_zsh_site | path exists) {
    $env.FPATH = (($env.FPATH? | default "") + ":" + $brew_zsh_site)
}

$env.PATH = ($env.PATH | split row (char esep) | prepend [
    $env.adb
    $env.BREW
    $env.CARGO
    $env.DOTNET_ROOT
    $env.DOTNET_ENV
    $env.JAVA_HOME
    $env.MAVEN_HOME
    $env.NVM_DIR
    $env.PIPX_BIN_DIR
    $env.PNPM_HOME    
    $env.RUSTUP
])

$env.STARSHIP_SHELL = "nu"
$env.EDITOR = "nvim"

$env.FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
$env.FZF_DEFAULT_COMMAND = "rg --files --hidden --follow --glob '!.git/*'"

mkdir ~/.cache/starship
if (which starship | is-empty) {
    print "starship not found; skipping starship init generation"
} else {
    starship init nu | save -f ~/.cache/starship/init.nu
}

mkdir ~/.cache/carapace
let carapace_init = ($env.HOME | path join ".cache" "carapace" "init.nu")

if (which carapace | is-empty) {
    print "carapace not found; skipping carapace init generation"
} else if not ($carapace_init | path exists) {
    carapace _carapace nushell | save -f $carapace_init
}
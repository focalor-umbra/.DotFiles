# Development environment setup
$env.adb = "/opt/homebrew/opt/android-platform-tools/platform-tools"
$env.BREW = "/opt/homebrew/bin"
$env.CARGO = $"($env.HOME)/.cargo/bin"
$env.NVM_DIR = $"($env.HOME)/.nvm"
$env.PNPM_HOME = $"($env.HOME)/Library/pnpm"
$env.JAVA_HOME = (ls /opt/homebrew/Cellar/openjdk/*/libexec/openjdk.jdk/Contents/Home | get 0 | get name)
$env.MAVEN_HOME = "/opt/homebrew/opt/maven"
$env.RUSTUP = "/opt/homebrew/opt/rustup"


$env.KUBAZULO_PATH = "/opt/kubazulo"
$env.SAML2AWS_PATH = "/opt/saml2aws"
$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"
$env.CARAPACE_LOG = 0
$env.CARAPACE_TOOLTIP = 1

$env.PATH = ($env.PATH | split row (char esep) | prepend [
    $env.adb
    $env.BREW
    $env.CARGO
    $env.NVM_DIR
    $env.PNPM_HOME
    $env.JAVA_HOME
    $env.MAVEN_HOME
    $env.RUSTUP
    $env.KUBAZULO_PATH
    $env.SAML2AWS_PATH
])

$env.STARSHIP_SHELL = "nu"
$env.EDITOR = "nvim"

$env.FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
$env.FZF_DEFAULT_COMMAND = "rg --files --hidden --follow --glob '!.git/*'"

mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu

mkdir ~/.cache/carapace
if (ls ~/.cache/carapace/init.nu | is-empty) {
    carapace _carapace nushell | save -f ~/.cache/carapace/init.nu
}
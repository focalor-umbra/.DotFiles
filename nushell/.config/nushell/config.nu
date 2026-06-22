# ~/.config/nushell/config.nu

############################################
# Helper functions
############################################
def confirm_kubectl_delete [resource, name] {
    let full_command = $"kubectl delete $resource $name"
    print $"Are you sure you want to run: $full_command? (y/n): "
    let response = (read)
    if $response == "y" {
        run $full_command
    } else {
        print "Command cancelled."
    }
}

def kexec [command?: string] {
    let namespaces = (kubectl get namespaces | lines | skip 1 | each { |line| $line | split row -r '\s+' | get 0 })
    let selected_ns = ($namespaces | fzf --bind 'enter:become(echo {4})')

    let pods = (kubectl get pods -n $selected_ns | lines | skip 1 | each { |line| $line | split row -r '\s+' | get 0 })
    let selected_pod = ($pods | fzf --bind 'enter:become(echo {4})')

    if ($command == null) {
        kubectl exec -it -n $selected_ns $selected_pod -- bash
    } else {
        kubectl exec -it -n $selected_ns $selected_pod -- $command
    }
}

def klogs [--follow(-f)] {
    let namespaces = (kubectl get namespaces | lines | skip 1 | each { |line| $line | split row -r '\s+' | get 0 })
    let selected_ns = ($namespaces | fzf --bind 'enter:become(echo {4})')

    let pods = (kubectl get pods -n $selected_ns | lines | skip 1 | each { |line| $line | split row -r '\s+' | get 0 })
    let selected_pod = ($pods | fzf --bind 'enter:become(echo {4})')

    if ($follow) {
        kubectl logs -f -n $selected_ns $selected_pod
    } else {
        kubectl logs -n $selected_ns $selected_pod
    }
}

def kfind [pattern: string] {
    let resources = (open ~/.cache/nushell/.kubectl_resources | lines | skip 1)
    
    $resources | each { |resource|
        let results = (kubectl get $resource --all-namespaces -o wide 2>/dev/null | lines)
        
        if ($results | length) > 1 {
            let matches = ($results | skip 1 | where { |line| $line =~ $pattern })
            
            if ($matches | length) > 0 {
                echo $"\n($resource):"
                echo ($results | first)
                echo $matches
            }
        }
    } | flatten
}

def kpfind [pattern: string] {
    let results = (kubectl get pods --all-namespaces -o wide | lines)
    let header = ($results | first)
    let matches = ($results | skip 1 | where { |line| $line =~ $pattern })
    
    if ($matches | length) > 0 {
        echo $header
        echo $matches | str
    }
}

def kstatus [flag: string] {
    match $flag {
        "-C" => { kpfind "Completed" }
        "-c" => { kpfind "CrashLoopBackOff" }
        "-f" => { kpfind "Failed" }
        "-p" => { kpfind "Pending" }
        "-r" => { kpfind "Running" }
        "-s" => { kpfind "Succeeded" }
        "-u" => { kpfind "Unknown" }
        "-h" => {
            print "Usage: kstatus -[C|c|f|p|r|s|u]"
            print "  -C  Completed"
            print "  -c  CrashLoopBackOff"
            print "  -f  Failed"
            print "  -p  Pending"
            print "  -r  Running"
            print "  -s  Succeeded"
            print "  -u  Unknown"
        }
    }
}

def khelp [topic?: string] {
    match $topic {
        "cmd" | "commands" | "usage" => { open ~/.config/nushell/.kubectl_aliases_usage}
        "res" | "resources" => { 
            open ~/.config/nushell/.kubectl_resources
            kubectl get customresourcedefinition | skip 1 | get name
        }
        _ => { print "usage: khelp (cmd|res)" }
    }
}


############################################
# Aliases
############################################
# Base commands
alias k = kubectl
def kd [resource, name] { confirm_kubectl_delete $resource $name }
alias kds = kubectl describe service
alias ke = kubectl edit
alias kg = kubectl get
alias kga = kubectl get --all-namespaces

# ConfigMaps
alias kcg = kubectl get configmaps
def kcd [name] { confirm_kubectl_delete "configmaps" $name }
alias kce = kubectl edit configmaps
alias kcds = kubectl describe configmaps
alias kcgy = kubectl get configmaps -o yaml

# Deployments
alias kdg = kubectl get deployments
def kdd [name] { confirm_kubectl_delete "deployment" $name }
alias kde = kubectl edit deployments
alias kdds = kubectl describe deployments
alias kdgy = kubectl get deployments -o yaml

# Other Resources
alias kepg = kubectl get endpoints
alias kevg = kubectl get events
alias kghpa = kubectl get horizontalpodautoscalers

# Ingress
alias kig = kubectl get ingress
def kid [name] { confirm_kubectl_delete "ingress" $name }
alias kie = kubectl edit ingress
alias kids = kubectl describe ingress
alias kigy = kubectl get ingress -o yaml

# Namespaces
alias knsg = kubectl get namespaces
def knsd [name] { confirm_kubectl_delete "namespaces" $name }
alias knse = kubectl edit namespaces
alias knsds = kubectl describe namespaces
alias knsgy = kubectl get namespaces -o yaml

# Nodes
alias kng = kubectl get nodes
def knd [name] { confirm_kubectl_delete "nodes" $name }
alias kne = kubectl edit nodes
alias knds = kubectl describe nodes
alias kngy = kubectl get nodes -o yaml
alias knt = kubectl top nodes

# Pods
alias kpg = kubectl get pods
def kpd [name] { confirm_kubectl_delete "pod" $name }
alias kpe = kubectl edit pods
alias kpds = kubectl describe pods
alias kpgy = kubectl get pods -o yaml
alias kpt = kubectl top pods

# Secrets
alias kscg = kubectl get secrets
def kscd [name] { confirm_kubectl_delete "secrets" $name }
alias ksce = kubectl edit secrets
alias kscds = kubectl describe secrets
alias kscgy = kubectl get secrets -o yaml

# Services
alias ksg = kubectl get services
alias kscg = kubectl get secrets
def ksd [name] { confirm_kubectl_delete "services" $name }
alias kse = kubectl edit services
alias ksds = kubectl describe services
alias ksgy = kubectl get services -o yaml

def code [...args] {
    let vscode_path = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    if ($args | is-empty) {
        ^$vscode_path .
    } else {
        ^$vscode_path ...$args
    }
}

############################################

def --env load-nvm [] {
    ^use /opt/homebrew/opt/nvm/nvm.sh
}

use ~/.config/nushell/themes/catppuccin-mocha.nu

if ("~/.cache/carapace/init.nu" | path exists) {
    source ~/.cache/carapace/init.nu
} else {
    print "carapace init not found; re-run mac-bootstrap preflight to generate it"
}

if ("~/.cache/starship/init.nu" | path exists) {
    use ~/.cache/starship/init.nu
}

$env.STARSHIP_SHELL = "nu"
$env.TRANSIENT_PROMPT_COMMAND = "->"

# Update config keys without overwriting the whole record (preserves Carapace external completer).
$env.config.show_banner = false
$env.config.ls.use_ls_colors = true
$env.config.ls.clickable_links = true
$env.config.rm.always_trash = true
$env.config.table.mode = "rounded"
$env.config.table.index_mode = "always"
$env.config.table.trim.methodology = "wrapping"
$env.config.table.trim.wrapping_try_keep_words = true
$env.config.history.max_size = 10000
$env.config.history.sync_on_enter = true
$env.config.history.file_format = "plaintext"
$env.config.completions.case_sensitive = false
$env.config.completions.quick = true
$env.config.completions.partial = true
$env.config.completions.algorithm = "prefix"

def update [] {
    brew update
    brew upgrade
    brew cleanup
}
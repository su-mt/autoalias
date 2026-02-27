# autoalias zsh hook

# Variable to store last command that failed with "command not found"
_autoalias_last_error=""

# Hook for command not found
command_not_found_handler() {
    local cmd="$1"
    _autoalias_last_error="$cmd"
    
    # Still show the error message
    echo "zsh: command not found: $cmd" >&2
    return 127
}

# Hook that runs before each command
autoalias_preexec() {
    # This runs before command execution
    # We'll check if command succeeds in precmd
}

# Hook that runs after each command
autoalias_precmd() {
    local exit_code=$?
    
    # If previous command succeeded (exit code 0) and we had a recent error
    if [[ $exit_code -eq 0 && -n "$_autoalias_last_error" ]]; then
        # Get the last executed command from history
        local last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
        
        # Extract just the command name (first word)
        local cmd_name=$(echo "$last_cmd" | awk '{print $1}')
        
        # Record the correction
        autoalias record "$_autoalias_last_error" "$cmd_name" 2>/dev/null
        
        # Clear the error
        _autoalias_last_error=""
    elif [[ $exit_code -ne 0 ]]; then
        # Command failed, clear any stored error
        _autoalias_last_error=""
    fi
}

# Add hooks to zsh
autoload -Uz add-zsh-hook
add-zsh-hook preexec autoalias_preexec
add-zsh-hook precmd autoalias_precmd

# Source aliases
if [[ -f ~/.autoalias/aliases.sh ]]; then
    source ~/.autoalias/aliases.sh
fi
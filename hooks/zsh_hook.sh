# autoalias zsh hook

# Temp file to store last error (persists between command executions)
_AUTOALIAS_ERROR_FILE="/tmp/autoalias_error_$$"

# Hook for command not found
command_not_found_handler() {
    local cmd="$1"
    # Save error to file so it persists
    echo "$cmd" > "$_AUTOALIAS_ERROR_FILE"
    
    # Still show the error message
    echo "zsh: command not found: $cmd" >&2
    return 127
}

# Hook that runs before each command
autoalias_preexec() {
    # Store the command that's about to be executed
    _autoalias_current_cmd="$1"
}

# Hook that runs after each command
autoalias_precmd() {
    local exit_code=$?
    
    # Check if there was a recent error
    if [[ -f "$_AUTOALIAS_ERROR_FILE" && -n "$_autoalias_current_cmd" && $exit_code -eq 0 ]]; then
        local last_error=$(cat "$_AUTOALIAS_ERROR_FILE")
        
        # Extract just the command name (first word)
        local cmd_name=$(echo "$_autoalias_current_cmd" | awk '{print $1}')
        
        # Record the correction
        autoalias record "$last_error" "$cmd_name" 2>/dev/null
        
        # Clear the error file
        rm -f "$_AUTOALIAS_ERROR_FILE"
    fi
    
    # Clear current command
    _autoalias_current_cmd=""
}

# Add hooks to zsh
autoload -Uz add-zsh-hook
add-zsh-hook preexec autoalias_preexec
add-zsh-hook precmd autoalias_precmd

# Source aliases
if [[ -f ~/.autoalias/aliases.sh ]]; then
    source ~/.autoalias/aliases.sh
fi
# autoalias bash hook

# Variable to store last command that failed with "command not found"
_autoalias_last_error=""
_autoalias_last_exit_code=0

# Hook for command not found
command_not_found_handle() {
    local cmd="$1"
    _autoalias_last_error="$cmd"
    
    # Still show the error message
    echo "bash: $cmd: command not found" >&2
    return 127
}

# Hook that runs after each command
_autoalias_prompt_command() {
    local exit_code=$?
    
    # If we have a stored error and the last command succeeded
    if [[ -n "$_autoalias_last_error" && $exit_code -eq 0 ]]; then
        # Get the last executed command from history
        local last_cmd=$(history 1 | sed 's/^[ ]*[0-9]*[ ]*//')
        
        # Extract just the command name (first word)
        local cmd_name=$(echo "$last_cmd" | awk '{print $1}')
        
        # Record the correction
        autoalias record "$_autoalias_last_error" "$cmd_name" 2>/dev/null
        
        # Clear the error
        _autoalias_last_error=""
    fi
}

# Add to PROMPT_COMMAND
if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="_autoalias_prompt_command"
else
    # Append if PROMPT_COMMAND already exists
    PROMPT_COMMAND="${PROMPT_COMMAND};_autoalias_prompt_command"
fi

# Source aliases
if [[ -f ~/.autoalias/aliases.sh ]]; then
    source ~/.autoalias/aliases.sh
fi
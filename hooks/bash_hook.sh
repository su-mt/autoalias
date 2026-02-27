# autoalias bash hook

# Temp file to store last error (persists between command executions)
_AUTOALIAS_ERROR_FILE="/tmp/autoalias_error_$$"
_autoalias_last_cmd=""

# Hook for command not found
command_not_found_handle() {
    local cmd="$1"
    # Save error to file so it persists
    echo "$cmd" > "$_AUTOALIAS_ERROR_FILE"
    
    # Still show the error message
    echo "bash: $cmd: command not found" >&2
    return 127
}

# Trap to capture command before execution
_autoalias_debug_trap() {
    # Capture the command that's about to be executed
    _autoalias_last_cmd="$BASH_COMMAND"
}

# Hook that runs after each command
_autoalias_prompt_command() {
    local exit_code=$?
    
    # If we have a stored error and the last command succeeded
    if [[ -f "$_AUTOALIAS_ERROR_FILE" && $exit_code -eq 0 && -n "$_autoalias_last_cmd" ]]; then
        local last_error=$(cat "$_AUTOALIAS_ERROR_FILE")
        
        # Extract just the command name (first word)
        local cmd_name=$(echo "$_autoalias_last_cmd" | awk '{print $1}')
        
        # Record the correction
        autoalias record "$last_error" "$cmd_name" 2>/dev/null
        
        # Clear the error file
        rm -f "$_AUTOALIAS_ERROR_FILE"
    fi
    
    # Clear last command
    _autoalias_last_cmd=""
}

# Set DEBUG trap to capture commands
trap '_autoalias_debug_trap' DEBUG

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
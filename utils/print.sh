#####################################
########### PRINT METHODS ###########
#####################################

### Set Debug mode
if ! $DEBUG; then
    exec >/dev/null 2>&1
fi

### Print method to override "exec >/dev/null 2>&1"
COLOR="`tput setaf 6`" # Default color: Cyan
DEFAULT="`tput sgr0`"
print(){
    if $DEBUG; then
        echo "${COLOR}$@${DEFAULT}"
    else
        exec >/dev/tty 2>&1
        echo "${COLOR}$@${DEFAULT}"
        exec >/dev/null 2>&1
    fi
}

### Print with GREEN color
print_ok(){
    local COLOR="`tput setaf 2`" # Green
    print $@
}

### Print with YELLOW color
print_warn(){
    local COLOR="`tput setaf 3`" # Yellow
    print $@
}

### Print with RED color
print_err(){
    local COLOR="`tput setaf 1`" # Red
    print $@
}

### Read user inputs
USER_INPUT=""
user_input(){
    local COLOR="`tput setaf 3`" # Yellow

    if $DEBUG; then
        read -p "${COLOR}$@${DEFAULT}" USER_INPUT
    else
        exec >/dev/tty 2>&1
        read -p "${COLOR}$@${DEFAULT}" USER_INPUT
        exec >/dev/null 2>&1
    fi
}

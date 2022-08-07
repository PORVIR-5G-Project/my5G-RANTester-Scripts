#!/bin/bash

# Check Kernel version
check_kernel_version() {
    VERSION_EXPECTED=5.4
    CURRENT_VERSION=$(uname -r | cut -c1-3)
    print "Checking Kernel version..."
    if (( $(echo "$CURRENT_VERSION == $VERSION_EXPECTED" |bc -l) )); then
        print_ok "-> Kernel version $CURRENT_VERSION OK."
    else
        print_err "-> You are NOT running the recommended kernel version. Please install version 5.4.90-generic."
        user_input "Do you want to continue (NOT recommended)? [y/N] "

        case $USER_INPUT in
            [Yy][Ee][Ss] ) ;;
            [Yy] ) ;;
            * ) print "Exiting..."; exit 1;;
        esac
    fi
}

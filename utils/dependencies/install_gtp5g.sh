#!/bin/bash

# Check and install gtp5g Kernel module
intall_gtp5g(){
    MODULE="gtp5g"
    if lsmod | grep "$MODULE" 2>&1 > /dev/null ; then
        print_ok "-> Module $MODULE installed!"
    else
        print_warn "-> Module $MODULE is not installed, installing..."

        git clone -b v0.4.0 https://github.com/free5gc/gtp5g.git
        cd gtp5g
        make
        make install

        cd $WORK_DIR
        rm -rf gtp5g

        if lsmod | grep "$MODULE" 2>&1 > /dev/null ; then
            print_ok "-> Module $MODULE installed successfully!"
        else
            print_err "-> ERROR during module $MODULE installation!"
            exit 1
        fi
    fi
}

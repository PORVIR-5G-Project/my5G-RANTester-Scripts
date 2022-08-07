#!/bin/bash

### Constants
WORK_DIR=$(pwd)
CORE_DIR="free5gc-compose/"
MULTI_GNB_DIR="my5G-RANTester-Multi-gNodeB/"

### Default value of CLI parameters
CLEAR='false'
DEBUG='false'
CORE_TASK='H'
NUM_UEs=1000

### Method to show help menu
show_help() {
    echo ""
    echo "free5GC helper"
    echo ""
    echo "Use: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo ""
    echo "  -h      Show this message and exit."
    echo "  -d      Enable debug mode (show all logs)."
    echo ""
    echo "  -i      Check and Install free5GC dependencies."
    echo "  -r      Build and run free5GC core."
    echo "  -f int  Fill free5GC core database. (Defaut: $NUM_UEs)"
    echo ""
    echo "  -s      Stop free5GC core."
    echo "  -c      Stop and clear free5GC core."
    echo ""
}

### Method to stop/clear free5GC core
stop_clear_core() {
    if [ -d "$CORE_DIR" ]; then
        cd $CORE_DIR

        # Stop core containers only
        if ! $CLEAR ; then
            docker compose down
            cd $WORK_DIR
            return;
        fi

        # Stop core containers and clear data
        docker compose down --rmi all -v --remove-orphans

        # Clear Multi gNB data
        if [ -d "$MULTI_GNB_DIR" ]; then
            docker compose down --rmi all -v --remove-orphans
        fi

        cd $WORK_DIR

        # Remove git directory
        rm -rf $CORE_DIR
    fi
}

install_core_deps() {
    print "-> Checking free5GC dependencies..."

    # Install gtp5g
    source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/utils/dependencies/gtp5g.sh)
    install_gtp5g
}

run_core() {
    ### Create free5GC containers
    print "Creating free5GC containers, it can take a while..."

    git clone https://github.com/gabriel-lando/free5gc-compose.git
    cd free5gc-compose/
    make base
    docker compose up --build -d
    cd $WORK_DIR
}

fill_core_database() {
    ### Fill free5GC database with IMSI info
    print "Adding necessary information to free5GC database..."
    git clone --recurse-submodules https://github.com/gabriel-lando/my5G-RANTester-free5GC-Database-Filler

    cd my5G-RANTester-free5GC-Database-Filler/

    wget https://raw.githubusercontent.com/gabriel-lando/free5gc-my5G-RANTester-docker/main/config/tester.yaml -O ./data/config.yaml

    # Generate .env file with the configs for docker compose
    echo NUM_DEVICES=$@ > .env

    docker compose up --build
    docker compose down --rmi all -v --remove-orphans
    cd $WORK_DIR
}

# Parse CLI parameters
while getopts ':f:hdirsc' 'OPTKEY'; do
    case ${OPTKEY} in
        d) DEBUG='true' ;;
        h) CORE_TASK="H" ;;
        i) CORE_TASK="I" ;;
        r) CORE_TASK="R" ;;
        f) CORE_TASK="f"; NUM_UEs=$OPTARG ;;
        s) CORE_TASK="S" ;;
        c) CORE_TASK="C" ;;
    esac
done

# Show help menu
if [ "$CORE_TASK" = "H" ]; then
    show_help
    exit 0
fi

# Load print methods
source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/utils/print.sh)

if [ "$CORE_TASK" = "I" ]; then
    install_core_deps
    exit 0
elif [ "$CORE_TASK" = "R" ]; then
    run_core
    exit 0
elif [ "$CORE_TASK" = "F" ]; then
    fill_core_database $NUM_UEs
    exit 0
elif [ "$CORE_TASK" = "S" ]; then
    stop_clear_core
    exit 0
elif [ "$CORE_TASK" = "C" ]; then
    CLEAR='true'
    stop_clear_core
    exit 0
fi

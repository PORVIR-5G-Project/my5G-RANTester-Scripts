#!/bin/bash

### Constants
CORE_WORK_DIR=$(pwd)
CORE_DIR="free5gc-compose/"
CORE_MULTI_GNB_DIR="my5G-RANTester-Multi-gNodeB/"

### Default value of CLI parameters
#VERBOSE='false'
CORE_CLEAR='false'
CORE_TASK='0'
CORE_NUM_UEs=1000

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
    echo "  -v      Enable verbose mode (show all logs)."
    echo ""
    echo "  -i      Check and Install free5GC dependencies."
    echo "  -r      Build and run free5GC core."
    echo "  -t      Download core compatible tester."
    echo "  -f int  Fill free5GC core database. (Defaut: $CORE_NUM_UEs)"
    echo ""
    echo "  -s      Stop free5GC core."
    echo "  -c      Stop and clear free5GC core."
    echo ""
}

### Method to stop/clear free5GC core
stop_clear_core() {
    print "Shuting down free5GC Core..."

    if [ -d "$CORE_DIR" ]; then
        cd $CORE_DIR

        # Stop core containers only
        if ! $CORE_CLEAR ; then
            docker compose down
            cd $CORE_WORK_DIR
            return;
        fi

        # Stop core containers and clear data
        docker compose down --rmi all -v --remove-orphans

        # Clear Multi gNB data
        if [ -d "$CORE_MULTI_GNB_DIR" ]; then
            docker compose down --rmi all -v --remove-orphans
        fi

        cd $CORE_WORK_DIR

        # Remove git directory
        rm -rf $CORE_DIR
    fi
}

install_core_deps() {
    print "-> Checking free5GC dependencies..."

    # Install gtp5g
    source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/utils/dependencies/gtp5g.sh)
    install_gtp5g
}

run_core() {
    ### Create free5GC containers
    print "Creating free5GC containers, it can take a while..."

    if [ ! -d "free5gc-compose" ]; then
        git clone https://github.com/gabriel-lando/free5gc-docker-v3.0.6 free5gc-compose
        cd free5gc-compose/
        make base
    else
        cd free5gc-compose/
    fi

    docker compose up --build -d
    cd $CORE_WORK_DIR
}

fill_core_database() {
    ### Fill free5GC database with IMSI info
    print "Adding necessary information to free5GC database..."

    if [ ! -d "my5G-RANTester-Database-Filler" ]; then
        git clone --recurse-submodules https://github.com/gabriel-lando/my5G-RANTester-free5GC-Database-Filler my5G-RANTester-Database-Filler
    fi
    
    cd my5G-RANTester-Database-Filler/

    wget https://raw.githubusercontent.com/gabriel-lando/free5gc-my5G-RANTester-docker/main/config/tester.yaml -O ./data/config.yaml

    # Generate .env file with the configs for docker compose
    echo NUM_DEVICES=$@ > .env

    docker compose up --build
    docker compose down --rmi all -v --remove-orphans
    cd $CORE_WORK_DIR
}

download_core_tester() {
    git clone -b throughput-test https://github.com/gabriel-lando/free5gc-my5G-RANTester-docker my5G-RANTester
}

# Parse CLI parameters
while getopts ':f:hvirtsc' 'OPTKEY'; do
    case ${OPTKEY} in
        v) VERBOSE='true' ;;
        h) CORE_TASK="H" ;;
        i) CORE_TASK="I" ;;
        r) CORE_TASK="R" ;;
        t) CORE_TASK="T" ;;
        f) CORE_TASK="F"; CORE_NUM_UEs=$OPTARG ;;
        s) CORE_TASK="S" ;;
        c) CORE_TASK="C" ;;
    esac
done


if [ "$CORE_TASK" = "0" ]; then
    # Ignore
    return;
elif [ "$CORE_TASK" = "H" ]; then
    # Show help menu
    show_help
    exit 0
fi

# Load print methods
source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/utils/print.sh)

if [ "$CORE_TASK" = "I" ]; then
    install_core_deps
    exit 0
elif [ "$CORE_TASK" = "R" ]; then
    run_core
    exit 0
elif [ "$CORE_TASK" = "T" ]; then
    download_core_tester
    exit 0
elif [ "$CORE_TASK" = "F" ]; then
    fill_core_database $CORE_NUM_UEs
    exit 0
elif [ "$CORE_TASK" = "S" ]; then
    stop_clear_core
    exit 0
elif [ "$CORE_TASK" = "C" ]; then
    CORE_CLEAR='true'
    stop_clear_core
    exit 0
fi

#!/bin/bash

### Constants
CORE_WORK_DIR=$(pwd)
CORE_DIR="docker_open5gs/"
CORE_MULTI_GNB_DIR="my5G-RANTester-Multi-gNodeB/"

### Default value of CLI parameters
#VERBOSE='false'
CORE_CLEAR='false'
CORE_TASK='0'
CORE_NUM_UEs=1000

### Method to show help menu
show_help() {
    echo ""
    echo "Open5GS helper"
    echo ""
    echo "Use: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo ""
    echo "  -h      Show this message and exit."
    echo "  -v      Enable verbose mode (show all logs)."
    echo ""
    echo "  -i      Check and Install Open5GS dependencies."
    echo "  -r      Build and run Open5GS core."
    echo "  -t      Download core compatible tester."
    echo "  -f int  Fill Open5GS core database. (Defaut: $CORE_NUM_UEs)"
    echo ""
    echo "  -s      Stop Open5GS core."
    echo "  -c      Stop and clear Open5GS core."
    echo ""
}

### Method to stop/clear Open5GS core
stop_clear_core() {
    print "Shuting down Open5GS Core..."

    if [ -d "$CORE_DIR" ]; then
        cd $CORE_DIR

        # Stop core containers only
        if ! $CORE_CLEAR ; then
            docker compose down
            cd $CORE_WORK_DIR
            return
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
    print "-> Checking Open5GS dependencies..."

    return
}

run_core() {
    ### Create Open5GS containers
    print "Creating Open5GS containers, it can take a while..."

    if [ ! -d "docker_open5gs" ]; then
        git clone https://github.com/my5G/docker_open5gs.git 
        cd docker_open5gs/base
        docker build --no-cache --force-rm -t docker_open5gs .

        cd ../mongo
        docker build --no-cache --force-rm -t docker_mongo .

        cd ..
    else
        cd docker_open5gs/
    fi

    echo -e "\n\n# HOST IP\nDOCKER_HOST_IP=$HOST_IP" >> .env

    docker compose up --build -d
    cd $CORE_WORK_DIR
}

fill_core_database() {
    ### Fill Open5GS database with IMSI info
    print "Adding necessary information to Open5GS database..."

    if [ ! -d "my5G-RANTester-Database-Filler" ]; then
        git clone --recurse-submodules https://github.com/PORVIR-5G-Project/my5G-RANTester-Open5GS-Database-Filler my5G-RANTester-Database-Filler
    fi

    cd my5G-RANTester-Database-Filler/

    wget https://raw.githubusercontent.com/PORVIR-5G-Project/open5gs-my5G-RANTester-docker/main/config/tester.yaml -O ./data/config.yaml

    # Generate .env file with the configs for docker compose
    echo NUM_DEVICES=$@ > .env

    docker compose up --build
    docker compose down --rmi all -v --remove-orphans
    cd $CORE_WORK_DIR
}

download_core_tester() {
   git clone https://github.com/PORVIR-5G-Project/open5gs-my5G-RANTester-docker my5G-RANTester
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
source <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/print.sh)

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

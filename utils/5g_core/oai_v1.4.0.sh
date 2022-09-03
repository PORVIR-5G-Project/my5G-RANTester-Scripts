#!/bin/bash

### Constants
CORE_WORK_DIR=$(pwd)
CORE_DIR="oai-cn5g-fed/docker-compose/"
CORE_MULTI_GNB_DIR="my5G-RANTester-Multi-gNodeB/"

### Default value of CLI parameters
#VERBOSE='false'
CORE_CLEAR='false'
CORE_TASK='0'
CORE_NUM_UEs=1000

### Method to show help menu
show_help() {
    echo ""
    echo "OpenAirInterface helper"
    echo ""
    echo "Use: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo ""
    echo "  -h      Show this message and exit."
    echo "  -v      Enable verbose mode (show all logs)."
    echo ""
    echo "  -i      Check and Install OpenAirInterface dependencies."
    echo "  -r      Build and run OpenAirInterface core."
    echo "  -t      Download core compatible tester."
    echo "  -f int  Fill OpenAirInterface core database. (Defaut: $CORE_NUM_UEs)"
    echo ""
    echo "  -s      Stop OpenAirInterface core."
    echo "  -c      Stop and clear OpenAirInterface core."
    echo ""
}

### Method to stop/clear OpenAirInterface core
stop_clear_core() {
    print "Shuting down OpenAirInterface Core..."

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
    print "-> Checking OpenAirInterface dependencies..."

    return
}

run_core() {
    ### Create OpenAirInterface containers
    print "Creating OpenAirInterface containers, it can take a while..."

    if [ ! -d "$CORE_DIR" ]; then
        # Pull OAI images
        docker pull oaisoftwarealliance/oai-amf:v1.4.0
        docker pull oaisoftwarealliance/oai-nrf:v1.4.0
        docker pull oaisoftwarealliance/oai-spgwu-tiny:v1.4.0
        docker pull oaisoftwarealliance/oai-smf:v1.4.0
        docker pull oaisoftwarealliance/oai-udr:v1.4.0
        docker pull oaisoftwarealliance/oai-udm:v1.4.0
        docker pull oaisoftwarealliance/oai-ausf:v1.4.0
        docker pull oaisoftwarealliance/oai-upf-vpp:v1.4.0
        docker pull oaisoftwarealliance/oai-nssf:v1.4.0

        # Retag OAI images
        docker image tag oaisoftwarealliance/oai-amf:v1.4.0 oai-amf:v1.4.0
        docker image tag oaisoftwarealliance/oai-nrf:v1.4.0 oai-nrf:v1.4.0
        docker image tag oaisoftwarealliance/oai-smf:v1.4.0 oai-smf:v1.4.0
        docker image tag oaisoftwarealliance/oai-spgwu-tiny:v1.4.0 oai-spgwu-tiny:v1.4.0
        docker image tag oaisoftwarealliance/oai-udr:v1.4.0 oai-udr:v1.4.0
        docker image tag oaisoftwarealliance/oai-udm:v1.4.0 oai-udm:v1.4.0
        docker image tag oaisoftwarealliance/oai-ausf:v1.4.0 oai-ausf:v1.4.0
        docker image tag oaisoftwarealliance/oai-upf-vpp:v1.4.0 oai-upf-vpp:v1.4.0
        docker image tag oaisoftwarealliance/oai-nssf:v1.4.0 oai-nssf:v1.4.0

        # Clone OAI repository
        git clone --branch v1.4.0 https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed.git 
        cd $CORE_DIR
        wget https://raw.githubusercontent.com/gabriel-lando/oai-my5G-RANTester-docker/main/config/docker-compose-basic-vpp-nrf.yaml -O docker-compose.yaml
    else
        cd $CORE_DIR
    fi

    docker compose up --build -d
    cd $CORE_WORK_DIR
}

fill_core_database() {
    print "ToDo: Adding necessary information to OpenAirInterface database..."
    ### Fill OpenAirInterface database with IMSI info
    # print "Adding necessary information to OpenAirInterface database..."

    # if [ ! -d "my5G-RANTester-Database-Filler" ]; then
    #     git clone --recurse-submodules https://github.com/gabriel-lando/my5G-RANTester-Open5GS-Database-Filler my5G-RANTester-Database-Filler
    # fi

    # cd my5G-RANTester-Database-Filler/

    # wget https://raw.githubusercontent.com/gabriel-lando/open5gs-my5G-RANTester-docker/main/config/tester.yaml -O ./data/config.yaml

    # # Generate .env file with the configs for docker compose
    # echo NUM_DEVICES=$@ > .env

    # docker compose up --build
    # docker compose down --rmi all -v --remove-orphans
    # cd $CORE_WORK_DIR
}

download_core_tester() {
   git clone -b throughput-test https://github.com/gabriel-lando/oai-my5G-RANTester-docker my5G-RANTester
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

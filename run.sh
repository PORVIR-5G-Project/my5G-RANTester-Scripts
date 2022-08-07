#!/bin/bash

### Get current directory
WORK_DIR=$(pwd)

### Default value of CLI parameters
START_DELAY=60
NUM_GNBs=10
NUM_UEs=1000
SLEEP_CONN=500
CORE=0

DEBUG='false'
CLEAR='false'
STOP_CLEAR='false'

### Method to show help menu
show_help(){
    echo ""
    echo "my5G-RANTester startup script"
    echo ""
    echo "Use: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo ""
    echo "  -h      Show this message and exit."
    echo ""
    echo "  -s      Stop experiment execution and clear environment."
    echo "  -l      Clear previous executions before run."
    echo ""
    echo "  -d      Enable debug mode (show all logs)."
    echo ""
    echo "  -c int  Select 5G Core to use:"
    echo "            1) free5GC v3.2.1"
    echo "            2) Open5GS v2.3.6"
    echo "            3) OpenAirInterface v1.3.0"
    echo ""
    echo "  -u int  Set the number of UEs to test. (Defaut: $NUM_UEs)"
    echo "  -g int  Set the number of gNBs to test. (Defaut: $NUM_GNBs)"
    echo "  -t int  Set the time in seconds to wait before start. (Defaut: $START_DELAY sec)"
    echo "  -w int  Set the time in ms to wait between each new connection. (Defaut: $SLEEP_CONN ms)"
    echo ""
}

# Method to define what 5G core will be used
set_5g_core() {
    if [ "$@" = "1" ]; then
        source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/utils/5g_core/free5gc.sh)
    elif [ "$@" = "2" ]; then
        source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/utils/5g_core/open5gs.sh)
    elif [ "$@" = "3" ]; then
        source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/utils/5g_core/oai.sh)
    else
        echo "ERROR: Please, select the 5G Core to use."
        exit 1
    fi
}

# Parse CLI parameters
while getopts ':g:t:u:w:c:ldhs' 'OPTKEY'; do
    case ${OPTKEY} in
        h) show_help; exit 0 ;;
        s) STOP_CLEAR='true' ;;
        l) CLEAR='true' ;;
        d) DEBUG='true' ;;
        c) set_5g_core $OPTARG ;;
        u) NUM_UEs=$OPTARG ;;
        g) NUM_GNBs=$OPTARG ;;
        t) START_DELAY=$OPTARG ;;
        w) SLEEP_CONN=$OPTARG ;;
    esac
done

### Enable Debug mode
if ! $DEBUG; then
    exec >/dev/null 2>&1
fi

#####################################
########### PRINT METHODS ###########
#####################################

# Load print methods
source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/utils/print.sh)

#####################################
########## PRE EXEC CHECKS ##########
#####################################

### Clear previous executions before run.
# ToDo: Change it
if $CLEAR || $STOP_CLEAR; then
    print "Cleaning environment from previous executions before run..."
    bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/stop_and_clear.sh)

    if $STOP_CLEAR; then
        exit 0;
    fi
fi

### Check Kernel version first
source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/utils/dependencies/kernel_version.sh)
check_kernel_version

### Install APT dependencies
print "Checking and installing dependencies..."
apt update 
apt -y install git ca-certificates curl gnupg pass gnupg2 lsb-release make build-essential

### Install Docker
source <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/utils/dependencies/docker.sh)
install_docker

### Install Core specific dependencies
install_core_deps

#####################################
########## START EXPERIMENT #########
#####################################

### Start 5G Core
run_core

### Fill core database with IMSI info
fill_core_database $NUM_UEs

### Pull images for the metrics collector
print "Preparing metrics collector containers..."

git clone https://github.com/lucas-schierholt/ColetorDeMetricas-DockerStats

cd ColetorDeMetricas-DockerStats/
chmod -R 777 nodered_data/
docker compose -f coleta.yml pull
cd $WORK_DIR

### Create my5G-RANTester container
print "Creating my5G-RANTester container, it can take a while..."
git clone https://github.com/gabriel-lando/free5gc-my5G-RANTester-docker

cd free5gc-my5G-RANTester-docker/
git submodule update --init --remote

# Create config for multiple gNB
wget https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/utils/generate_compose_multi_gnb.sh -O generate_compose_multi_gnb.sh
chmod +x generate_compose_multi_gnb.sh
./generate_compose_multi_gnb.sh -g $NUM_GNBs -u $NUM_UEs

# Set test parameters for docker compose
echo TEST_PARAMETERS=load-test-parallel -n $((NUM_UEs / NUM_GNBs)) -d $SLEEP_CONN -t $START_DELAY -a > .env

docker compose -f docker-multi.yaml up --build -d
cd $WORK_DIR

### Start metrics collector
print "Starting metrics collector containers..."

cd ColetorDeMetricas-DockerStats/
docker compose -f coleta.yml up -d
cd $WORK_DIR

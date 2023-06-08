#!/bin/bash

### Get current directory
WORK_DIR=$(pwd)

### Default value of CLI parameters
RUN_START_DELAY=60
RUN_NUM_GNBs=10
RUN_NUM_UEs=1000
RUN_SLEEP_CONN=500
RUN_CORE_5G=0
RUN_TEST=1

VERBOSE='false'
RUN_CLEAR='false'
RUN_STOP_CLEAR='false'

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
    echo "  -v      Enable verbose mode (show all logs)."
    echo ""
    echo "  -c int  Select 5G Core to use:"
    echo "            1) free5GC v3.0.6"
    echo "            2) free5GC v3.2.1"
    echo "            3) Open5GS v2.3.6"
    echo "            4) OpenAirInterface v1.4.0"
    echo ""
    echo "  -e int  Select the experiment to run:"
    echo "            1) Connectivity test (Default)"
    echo "            2) Throughput test"
    echo ""
    echo "  -u int  Set the number of UEs to test. (Defaut: $RUN_NUM_UEs)"
    echo "  -g int  Set the number of gNBs to test. (Defaut: $RUN_NUM_GNBs)"
    echo "  -t int  Set the time in seconds to wait before start. (Defaut: $RUN_START_DELAY sec)"
    echo "  -w int  Set the time in ms to wait between each new connection. (Defaut: $RUN_SLEEP_CONN ms)"
    echo ""
}

# Parse CLI parameters
while getopts ':e:g:t:u:w:c:vhls' 'OPTKEY'; do
    case ${OPTKEY} in
        h) show_help; exit 0 ;;
        s) RUN_STOP_CLEAR='true' ;;
        l) RUN_CLEAR='true' ;;
        v) VERBOSE='true' ;;
        c) RUN_CORE_5G=$OPTARG ;;
        u) RUN_NUM_UEs=$OPTARG ;;
        g) RUN_NUM_GNBs=$OPTARG ;;
        t) RUN_START_DELAY=$OPTARG ;;
        w) RUN_SLEEP_CONN=$OPTARG ;;
        e) RUN_TEST=$OPTARG ;;
    esac
done

### Enable Debug mode
if ! [ "$VERBOSE" = "true" ]; then
    exec >/dev/null 2>&1
fi

#####################################
########### PRINT METHODS ###########
#####################################

# Load print methods
source <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/print.sh)

#####################################
########## PRE EXEC CHECKS ##########
#####################################

### Clear previous executions before run.
# ToDo: Change it
if $RUN_CLEAR || $RUN_STOP_CLEAR; then
    print "Cleaning environment from previous executions before run..."
    bash <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/stop_and_clear.sh)

    if $RUN_STOP_CLEAR; then
        exit 0;
    fi
fi

### Define what 5G core will be used
if [ "$RUN_CORE_5G" = "1" ]; then
    source <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/5g_core/free5gc_v3.0.6.sh)
elif [ "$RUN_CORE_5G" = "2" ]; then
    source <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/5g_core/free5gc_v3.2.1.sh)
elif [ "$RUN_CORE_5G" = "3" ]; then
    source <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/5g_core/open5gs_v2.3.6.sh)
elif [ "$RUN_CORE_5G" = "4" ]; then
    source <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/5g_core/oai_v1.4.0.sh)
else
    print_err "ERROR: Please, select the 5G Core to use. Use '-h' for more info."
    exit 1
fi

### Check Kernel version first
source <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/dependencies/kernel_version.sh)
check_kernel_version

### Install APT dependencies
print "Checking and installing dependencies..."
apt update 
apt -y install git ca-certificates curl gnupg pass gnupg2 lsb-release make build-essential

### Install Docker
source <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/dependencies/docker.sh)
install_docker

### Install Core specific dependencies
install_core_deps

#####################################
########## START EXPERIMENT #########
#####################################

### Start 5G Core
run_core

### Fill core database with IMSI info
fill_core_database $RUN_NUM_UEs

### Prepare metrics colector
source <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/metrics_collector.sh)
prepare_metrics_collector

### Create my5G-RANTester container
print "Creating my5G-RANTester container, it can take a while..."

# Clone tester repository
download_core_tester

cd my5G-RANTester/
git submodule update --init --remote

# Create config for multiple gNB
wget https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/utils/generate_compose_multi_gnb.sh -O generate_compose_multi_gnb.sh
chmod +x generate_compose_multi_gnb.sh
./generate_compose_multi_gnb.sh -g $RUN_NUM_GNBs -u $RUN_NUM_UEs

# Set test parameters for docker compose
if [ "$RUN_TEST" = "1" ]; then
    echo TEST_PARAMETERS=load-test-parallel -n $((RUN_NUM_UEs / RUN_NUM_GNBs)) -d $RUN_SLEEP_CONN -t $RUN_START_DELAY -a > .env
elif [ "$RUN_TEST" = "2" ]; then
    echo TEST_PARAMETERS=ue > .env
else
    print_err "ERROR: Wrong test case. Using default (Connectivity test)."
    echo TEST_PARAMETERS=load-test-parallel -n $((RUN_NUM_UEs / RUN_NUM_GNBs)) -d $RUN_SLEEP_CONN -t $RUN_START_DELAY -a > .env
fi

docker compose -f docker-multi.yaml up --build -d
cd $WORK_DIR

### Start metrics collector
start_metrics_collector

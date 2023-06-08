#!/bin/bash

### Get current directory
WORK_DIR=$(pwd)

### Default value of CLI parameters
START_DELAY=60
NUM_UEs=1000
SLEEP_CONN=500
HOST_IP=""

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
    echo "  -c      Clear previous executions before run."
    echo "  -d      Enable debug mode (show all logs)."
    echo "  -h      Show this message and exit."
    echo "  -i str  Host IP Address"
    echo "  -s      Stop experiment execution and clear environment."
    echo "  -t int  Set the time in seconds to wait before start. (Defaut: $START_DELAY sec)"
    echo "  -u int  Set the number of UEs to test. (Defaut: $NUM_UEs)"
    echo "  -w int  Set the time in ms to wait between each new connection. (Defaut: $SLEEP_CONN ms)"
    echo ""
}

# Parse CLI parameters
while getopts ':i:t:u:w:cdhs' 'OPTKEY'; do
    case ${OPTKEY} in
        c) CLEAR='true' ;;
        d) DEBUG='true' ;;
        h) show_help; exit 0 ;;
        i) HOST_IP=$OPTARG ;;
        s) STOP_CLEAR='true' ;;
        t) START_DELAY=$OPTARG ;;
        u) NUM_UEs=$OPTARG ;;
        w) SLEEP_CONN=$OPTARG ;;
    esac
done

# Check if Host IP was provided
if [ -z "$HOST_IP" ] && ! $STOP_CLEAR; then
    show_help
    exit 0
fi

### Enable Debug mode
if ! $DEBUG; then
    exec >/dev/null 2>&1
fi

#####################################
########### PRINT METHODS ###########
#####################################

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

#####################################
########## PRE EXEC CHECKS ##########
#####################################

### Clear previous executions before run.
if $CLEAR || $STOP_CLEAR; then
    print "Cleaning environment from previous executions before run..."
    bash <(curl -s https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Scripts/main/stop_and_clear.sh)

    if $STOP_CLEAR; then
        exit 0;
    fi
fi

### Check Kernel version first
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

### Install dependencies
print "Checking and installing dependencies..."
apt update 
apt -y install git ca-certificates curl gnupg pass gnupg2 lsb-release make build-essential

### Check and install Docker
if docker compose version | grep "Docker Compose version v2" 2>&1 > /dev/null; then
    print_ok "-> Docker and Docker Compose OK."
else
    print_warn "-> Docker and/or Docker Compose v2 NOT installed, installing..."
    apt -y remove docker docker.io containerd runc

    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg  --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg

    echo  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update
    apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

### Expose Docker API via TCP
DOCKER_API_TCP="tcp://0.0.0.0:2375"
if ! cat /lib/systemd/system/docker.service | grep "$DOCKER_API_TCP" 2>&1 > /dev/null; then
    print "-> Exposing Docker API via TCP at $DOCKER_API_TCP..."

    sed -i "/^ExecStart=/ s|$| -H $DOCKER_API_TCP|" /lib/systemd/system/docker.service

    systemctl daemon-reload
    service docker restart
fi

#####################################
########## START EXPERIMENT #########
#####################################

### Create Open5GS containers
print "Creating Open5GS containers, it can take a while..."

git clone https://github.com/my5G/docker_open5gs.git
cd docker_open5gs/base
docker build --no-cache --force-rm -t docker_open5gs .

cd ../mongo
docker build --no-cache --force-rm -t docker_mongo .

cd ..
echo -e "\n\n# HOST IP\nDOCKER_HOST_IP=$HOST_IP" >> .env

docker compose up --build -d
cd $WORK_DIR

### Fill Open5GS database with IMSI info
print "Adding necessary information to Open5GS database..."
git clone --recurse-submodules https://github.com/PORVIR-5G-Project/my5G-RANTester-Open5GS-Database-Filler

cd my5G-RANTester-Open5GS-Database-Filler/

wget https://raw.githubusercontent.com/PORVIR-5G-Project/open5gs-my5G-RANTester-docker/main/config/tester.yaml -O ./data/config.yaml

# Generate .env file with the configs for docker compose
echo NUM_DEVICES=$NUM_UEs > .env

docker compose up --build
docker compose down --rmi all -v --remove-orphans
cd $WORK_DIR

### Pull images for the metrics collector
print "Preparing metrics collector containers..."

git clone https://github.com/lucas-schierholt/ColetorDeMetricas-DockerStats

cd ColetorDeMetricas-DockerStats/
chmod -R 777 nodered_data/
docker compose -f coleta.yml pull
cd $WORK_DIR

### Create my5G-RANTester container
print "Creating my5G-RANTester container, it can take a while..."
git clone https://github.com/PORVIR-5G-Project/open5gs-my5G-RANTester-docker

cd open5gs-my5G-RANTester-docker/
git submodule init
git submodule update --remote

# Set test parameters for docker compose
echo TEST_PARAMETERS=load-test-parallel -n $NUM_UEs -d $SLEEP_CONN -t $START_DELAY -a > .env

docker compose up --build -d
cd $WORK_DIR

### Start metrics collector
print "Starting metrics collector containers..."

cd ColetorDeMetricas-DockerStats/
docker compose -f coleta.yml up -d
cd $WORK_DIR

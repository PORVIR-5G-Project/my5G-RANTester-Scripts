#!/bin/bash

# Get current directory
WORK_DIR=$(pwd)

# Method to show help menu
show_help(){
    echo ""
    echo "my5G-RANTester startup script"
    echo ""
    echo "Use: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c      Clear previous executions before run."
    echo "  -d      Enable debug mode. Show all logs."
    echo "  -h      Show this message and exit."
    echo ""
}

# Parse parameters
DEBUG='false'
CLEAR='false'
while getopts ':cdh' 'OPTKEY'; do
    case ${OPTKEY} in
        c) CLEAR='true' ;;
        d) DEBUG='true' ;;
        h) show_help; exit 0 ;;
    esac
done

# Enable Debug mode
if ! $DEBUG; then
    exec >/dev/null 2>&1
fi

#####################################
########### PRINT METHODS ###########
#####################################

# Print method to override "exec >/dev/null 2>&1"
COLOR="`tput setaf 4`" # Default color: Blue
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

# Print with GREEN color
print_ok(){
    local COLOR="`tput setaf 2`" # Green
    print $@
}

# Print with YELLOW color
print_warn(){
    local COLOR="`tput setaf 3`" # Yellow
    print $@
}

# Print with RED color
print_err(){
    local COLOR="`tput setaf 1`" # Red
    print $@
}

# Read user inputs
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
#####################################

# Clear previous executions before run.
if $CLEAR; then
    print "Cleaning environment from previous executions before run..."
    bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/stop_and_clear.sh)
fi

# Check Kernel version first
VERSION_EXPECTED=5.4
CURRENT_VERSION=$(uname -r | cut -c1-3)
print "Checking Kernel version..."
if (( $(echo "$CURRENT_VERSION == $VERSION_EXPECTED" |bc -l) )); then
    print_ok "->Kernel version $CURRENT_VERSION OK."
else
    print_err "-> You are NOT running the recommended kernel version. Please install version 5.4.90-generic."
    user_input "Do you want to continue (NOT recommended)? [y/N] "

    case $USER_INPUT in
        [Yy][Ee][Ss] ) ;;
        [Yy] ) ;;
        * ) print "Exiting..."; exit 1;;
    esac
fi

# Install dependencies
print "Checking and installing dependencies..."
apt update 
apt -y install git ca-certificates curl gnupg pass gnupg2 lsb-release make build-essential

# Check and install Docker
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

# Expose Docker API via TCP
DOCKER_API_TCP="tcp://0.0.0.0:2375"
if ! cat /lib/systemd/system/docker.service | grep "$DOCKER_API_TCP" 2>&1 > /dev/null; then
    print "-> Exposing Docker API via TCP at $DOCKER_API_TCP..."

    sed -i "/^ExecStart=/ s|$| -H $DOCKER_API_TCP|" /lib/systemd/system/docker.service

    systemctl daemon-reload
    service docker restart
fi

# Check and install gtp5g Kernel module
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

# Create Free5G containers
print "Creating Free5G containers, it can take a while..."

git clone https://github.com/my5G/free5gc-docker-v3.0.6.git
cd free5gc-docker-v3.0.6/
make base
docker compose build

docker compose up -d
cd $WORK_DIR

# Pull images for the metrics collector
print "Preparing metrics collector containers..."

git clone https://github.com/lucas-schierholt/ColetorDeMetricas-DockerStats

cd ColetorDeMetricas-DockerStats/
chmod -R 777 nodered_data/
docker compose -f coleta.yml pull
cd $WORK_DIR

# Create my5G-RANTester container
print "Creating my5G-RANTester container, it can take a while..."
git clone https://github.com/gabriel-lando/free5gc-my5G-RANTester-docker

cd free5gc-my5G-RANTester-docker/
git submodule init
git submodule update --remote

docker compose up --build -d
cd $WORK_DIR

# Start metrics collector
print "Starting metrics collector containers..."

cd ColetorDeMetricas-DockerStats/
docker compose -f coleta.yml up -d
cd $WORK_DIR

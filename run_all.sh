#!/bin/bash

WORK_DIR=$(pwd)

# Check Kernel version first
VERSION_EXPECTED=5.4
CURRENT_VERSION=$(uname -r | cut -c1-3)
if (( $(echo "$CURRENT_VERSION == $VERSION_EXPECTED" |bc -l) )); then
    echo "-> Kernel version $CURRENT_VERSION OK."
else
    echo "-> WARN You are NOT running the recommended kernel version. Please install a version 5.4.90-generic."
    read -p "Do you want to continue (NOT recommended)? [y/N] " yn

    case $yn in
        [Yy][Ee][Ss] ) ;;
        [Yy] ) ;;
        * ) echo "Exiting..."; exit 1;;
    esac
fi

# Install dependencies
echo "Checking and installing dependencies..."
apt update &> /dev/null
apt -y install git ca-certificates curl gnupg pass gnupg2 lsb-release make build-essential &> /dev/null

# Check and install Docker
if docker compose version | grep "Docker Compose version v2" > /dev/null 2>&1; then
    echo "-> Docker and Docker Compose OK."
else
    echo "-> Docker and/or Docker Compose v2 NOT installed, installing..."
    apt -y remove docker docker.io containerd runc &> /dev/null

    mkdir -p /etc/apt/keyrings &> /dev/null
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg  --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg

    echo  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update &> /dev/null
    apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin &> /dev/null
fi

# Expose Docker API via TCP
DOCKER_API_TCP="tcp://0.0.0.0:2375"
if ! cat /lib/systemd/system/docker.service | grep "$DOCKER_API_TCP" &> /dev/null; then
    echo "-> Exposing Docker API via TCP at $DOCKER_API_TCP..."

    sed -i "/^ExecStart=/ s|$| -H $DOCKER_API_TCP|" /lib/systemd/system/docker.service
    
    systemctl daemon-reload
    service docker restart
fi

# Check and install gtp5g Kernel module
MODULE="gtp5g"
if lsmod | grep "$MODULE" &> /dev/null ; then
    echo "-> Module $MODULE installed!"
else
    echo "-> Module $MODULE is not installed, installing..."

    git clone -b v0.4.0 https://github.com/free5gc/gtp5g.git &> /dev/null
    cd gtp5g
    make > /dev/null
    make install > /dev/null

    cd $WORK_DIR
    rm -rf gtp5g

    if lsmod | grep "$MODULE" &> /dev/null ; then
        echo "-> Module $MODULE installed successfully!"
    else
        echo "-> ERROR during module $MODULE installation!"
        exit 1
    fi
fi

# Create Free5G containers
echo "Creating Free5G containers, it can take a while..."

git clone https://github.com/my5G/free5gc-docker-v3.0.6.git &> /dev/null
cd free5gc-docker-v3.0.6/
make base &> /dev/null
docker compose build &> /dev/null

docker compose up -d &> /dev/null
cd $WORK_DIR

# Pull images for the metrics collector
echo "Preparing metrics collector containers..."

git clone https://github.com/lucas-schierholt/ColetorDeMetricas-DockerStats &> /dev/null

cd ColetorDeMetricas-DockerStats/
chmod -R 777 nodered_data/
docker compose -f coleta.yml pull &> /dev/null
cd $WORK_DIR

# Create my5G-RANTester container
echo "Creating my5G-RANTester container, it can take a while..."
git clone https://github.com/gabriel-lando/free5gc-my5G-RANTester-docker &> /dev/null

cd free5gc-my5G-RANTester-docker/
git submodule init &> /dev/null
git submodule update --remote &> /dev/null

docker compose up --build -d &> /dev/null
cd $WORK_DIR

# Start metrics collector
echo "Starting metrics collector containers..."

cd ColetorDeMetricas-DockerStats/
docker compose -f coleta.yml up -d &> /dev/null
cd $WORK_DIR

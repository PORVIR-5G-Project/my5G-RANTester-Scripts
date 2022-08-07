#!/bin/bash

### Get current directory
WORK_DIR=$(pwd)

### Default value of CLI parameters
IN_COMPOSE_NAME=docker-compose.yaml
OUT_COMPOSE_NAME=docker-multi.yaml
SETTINGS_PATH=config
SETTINGS_FILE=tester.yaml
NUM_GNBs=1
NUM_UEs=1

### Method to show help menu
show_help(){
    echo ""
    echo "my5G-RANTester script to generate config to multi gNB"
    echo ""
    echo "Use: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h      Show this message and exit."
    echo "  -g int  Set the number of gNodeB to test. (Defaut: $NUM_GNBs)"
    echo "  -i str  Set the name of the input Docker Compose file. (Defaut: $IN_COMPOSE_NAME)"
    echo "  -o str  Set the name of the output Docker Compose file. (Defaut: $OUT_COMPOSE_NAME)"
    echo "  -p str  Settings file path. (Defaut: ./$SETTINGS_PATH/)"
    echo "  -s str  Settings file name. (Defaut: $SETTINGS_FILE)"
    echo "  -u int  Set the number of UEs to test. (Defaut: $NUM_UEs)"
    echo ""
}

# Parse CLI parameters
while getopts ':g:i:o:p:s:u:h' 'OPTKEY'; do
    case ${OPTKEY} in
        h) show_help; exit 0 ;;
        g) NUM_GNBs=$OPTARG ;;
        i) IN_COMPOSE_NAME=$OPTARG ;;
        o) OUT_COMPOSE_NAME=$OPTARG ;;
        p) SETTINGS_PATH=$OPTARG ;;
        s) SETTINGS_FILE=$OPTARG ;;
        u) NUM_UEs=$OPTARG ;;
    esac
done

# Clone repository with the script
git clone --recurse-submodules https://github.com/gabriel-lando/my5G-RANTester-Multi-gNodeB
cd my5G-RANTester-Multi-gNodeB/

# Create output compose file
touch $WORK_DIR/$OUT_COMPOSE_NAME

# Generate .env file with the configs for docker compose
echo TESTER_PATH=$WORK_DIR > .env
echo NUM_UE=$NUM_UEs >> .env
echo NUM_GNB=$NUM_GNBs >> .env
echo CONFIG_PATH=$SETTINGS_PATH >> .env
echo CONFIG_FILE=$SETTINGS_FILE >> .env
echo IN_COMPOSE=$IN_COMPOSE_NAME >> .env
echo OUT_COMPOSE=$OUT_COMPOSE_NAME >> .env

# Run scripts
docker compose up --build
docker compose down --rmi all -v --remove-orphans
cd $WORK_DIR

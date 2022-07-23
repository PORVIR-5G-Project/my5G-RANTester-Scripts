#!/bin/bash

WORK_DIR=$(pwd)

# Stop metrics collector containers and clear data
METRICS_COLLECTOR_DIR="ColetorDeMetricas-DockerStats/"
if [ -d "$METRICS_COLLECTOR_DIR" ]; then
    cd $METRICS_COLLECTOR_DIR/
    docker compose -f coleta.yml down --rmi all -v --remove-orphans

    cd $WORK_DIR

    # Remove git directory
    rm -rf $METRICS_COLLECTOR_DIR/
    # Remove DB directory
    rm -rf /data/influxdb
fi

# Stop free5GC my5G-RANTester container and clear data
TESTER_DIR="free5gc-my5G-RANTester-docker/"
if [ -d "$TESTER_DIR" ]; then
    cd $TESTER_DIR
    docker compose down --rmi all -v --remove-orphans

    cd $WORK_DIR

    # Remove git directory
    rm -rf $TESTER_DIR
fi

# Stop Open5GS my5G-RANTester container and clear data
TESTER_DIR="open5gs-my5G-RANTester-docker/"
if [ -d "$TESTER_DIR" ]; then
    cd $TESTER_DIR
    docker compose down --rmi all -v --remove-orphans

    cd $WORK_DIR

    # Remove git directory
    rm -rf $TESTER_DIR
fi

# Stop free5GC containers and clear data
FREE5GC_CORE_DIR="free5gc-docker-v3.0.6/"
if [ -d "$FREE5GC_CORE_DIR" ]; then
    cd $FREE5GC_CORE_DIR
    docker compose down --rmi all -v --remove-orphans

    cd $WORK_DIR

    # Remove git directory
    rm -rf $FREE5GC_CORE_DIR
fi

# Stop Open5GS containers and clear data
OPEN5GS_CORE_DIR="docker_open5gs/"
if [ -d "$OPEN5GS_CORE_DIR" ]; then
    cd $OPEN5GS_CORE_DIR
    docker compose down --rmi all -v --remove-orphans

    cd $WORK_DIR

    # Remove git directory
    rm -rf $OPEN5GS_CORE_DIR
fi

# Clear free5GC database filler data
DATABASE_FILLER_DIR="my5G-RANTester-free5GC-Database-Filler/"
if [ -d "$DATABASE_FILLER_DIR" ]; then
    cd $DATABASE_FILLER_DIR
    docker compose down --rmi all -v --remove-orphans

    cd $WORK_DIR

    # Remove git directory
    rm -rf $DATABASE_FILLER_DIR
fi

# Clear Open5GS database filler data
DATABASE_FILLER_DIR="my5G-RANTester-Open5GS-Database-Filler/"
if [ -d "$DATABASE_FILLER_DIR" ]; then
    cd $DATABASE_FILLER_DIR
    docker compose down --rmi all -v --remove-orphans

    cd $WORK_DIR

    # Remove git directory
    rm -rf $DATABASE_FILLER_DIR
fi

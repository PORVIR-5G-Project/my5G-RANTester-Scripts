#!/bin/bash

WORK_DIR=$(pwd)

# Stop metrics collector containers and clear data
METRICS_COLLECTOR_DIR="ColetorDeMetricas-DockerStats/"
if [ -d "$METRICS_COLLECTOR_DIR" ]; then
    cd $METRICS_COLLECTOR_DIR/
    docker compose -f coleta.yml down

    cd $WORK_DIR

    # Remove git directory
    rm -rf $METRICS_COLLECTOR_DIR/
    # Remove DB directory
    rm -rf /data/influxdb
fi

# Stop my5G-RANTester container and clear data
TESTER_DIR="free5gc-my5G-RANTester-docker/"
if [ -d "$TESTER_DIR" ]; then
    cd $TESTER_DIR
    docker compose down

    cd $WORK_DIR

    # Remove git directory
    rm -rf $TESTER_DIR
fi

# Stop free5GC containers and clear data
FREE5GC_CORE_DIR="free5gc-docker-v3.0.6/"
if [ -d "$FREE5GC_CORE_DIR" ]; then
    cd $FREE5GC_CORE_DIR
    docker compose down

    cd $WORK_DIR

    # Remove git directory
    rm -rf $FREE5GC_CORE_DIR
fi

#!/bin/bash

### Pull images for the metrics collector
prepare_metrics_collector() {
    print "Preparing metrics collector containers..."

    git clone https://github.com/lucas-schierholt/ColetorDeMetricas-DockerStats

    cd ColetorDeMetricas-DockerStats/
    chmod -R 777 nodered_data/
    docker compose -f coleta.yml pull
    cd $WORK_DIR
}

### Start metrics collector
start_metrics_collector() {
    print "Starting metrics collector containers..."

    cd ColetorDeMetricas-DockerStats/
    docker compose -f coleta.yml up -d
    cd $WORK_DIR
}

### Stop metrics collector
stop_metrics_collector() {
    print "Stopping metrics collector containers..."

    cd ColetorDeMetricas-DockerStats/
    docker compose -f coleta.yml down
    cd $WORK_DIR
}

### Stop metrics collector containers and clear data
clear_metrics_collector() {
    print "Cleaning metrics collector containers and data..."

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
}

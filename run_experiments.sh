#!/bin/bash
# Run: screen -L -Logfile output.txt ./run_experiments.sh

echo "Run connectivity tests"
for c in 2 3; do
    echo "Run core $c tests"
    for w in 500 400 300 200 100; do
        for i in 1 3 5 7 9 11; do
            echo "Running experiment $i (w=$w)"
            bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/run.sh) -c $c -e 1 -g $i -u $((100*$i)) -t 60 -w $w -v

            echo "Waiting for experiment $i (w=$w) to finish"
            sleep $((2*60))

            echo "Collecting experiment $i (w=$w) data"
            bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/capture_and_parse_logs.sh) my5grantester-logs-$c-$w-$i.csv

            echo "Collecting experiment $i data from influxdb"
            docker exec influxdb sh -c "influx query 'from(bucket:\"database\") |> range(start:-5m)' --raw" > my5grantester-logs-influxdb-$c-$w-$i.csv

            echo "Clear experiment $i (w=$w) environment"
            bash stop_only.sh >/dev/null 2>&1
            docker image prune --filter="dangling=true" -f >/dev/null 2>&1
            docker volume prune -f >/dev/null 2>&1
        done
    done
done

echo "Cleaning environment"
bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/stop_and_clear.sh)
docker image prune -a -f >/dev/null 2>&1
docker volume prune -f >/dev/null 2>&1

echo "Run throughtput tests"
# Run 15 times all throughput tests
for e in $(seq 1 16); do
    for c in 1 3; do
        echo "Run core $c tests (exec $e)"
        for i in 1 2 4 6 8 10; do
            echo "Running experiment $i"
            bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/run.sh) -c $c -e 2 -g $i -v

            echo "Waiting connections for experiment $i"
            sleep $((1*60))

            echo "Starting experiment $i"
            for j in $(seq 0 $(($i - 1))); do
                IP=$(docker exec -ti my5grantester$j sh -c "ip -4 addr show uetun1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
                docker exec my5grantester$j sh -c "iperf -c iperf --bind $IP -t 60 -i 1 -y C" > my5grantester-iperf-$e-$c-$i-$j.csv &
            done

            echo "Waiting for experiment $i to finish"
            sleep $((80))

            echo "Collecting experiment $i data from influxdb"
            docker exec influxdb sh -c "influx query 'from(bucket:\"database\") |> range(start:-5m)' --raw" > my5grantester-iperf-influxdb-$e-$c-$i.csv

            echo "Clear experiment $i environment"
            bash stop_only.sh >/dev/null 2>&1
            docker image prune --filter="dangling=true" -f >/dev/null 2>&1
            docker volume prune -f >/dev/null 2>&1
        done
    done
done

echo "Cleaning environment"
bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/stop_and_clear.sh)
docker image prune -a -f >/dev/null 2>&1
docker volume prune -f >/dev/null 2>&1

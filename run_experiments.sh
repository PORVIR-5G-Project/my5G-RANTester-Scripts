#!/bin/bash

echo "Run connectivity tests"

for c in 2 3; do
    echo "Run core $c tests"
    for i in $(seq 1 11); do
        echo "Running experiment $i"
        bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/run.sh) -c $c -e 1 -g $i -u $((100*$i)) -t 60 -w 500

        echo "Waiting for experiment $i to finish"
        sleep $((3*60))

        echo "Collecting experiment $i data"
        bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/capture_and_parse_logs.sh) my5grantester-logs-$c-$i.csv

        echo "Clear experiment $i environment"
        bash stop_only.sh >/dev/null 2>&1
        docker image prune --filter="dangling=true" >/dev/null 2>&1
        docker volume prune -f >/dev/null 2>&1
    done
done


echo "Run throughtput tests"

for c in 1 3; do
    echo "Run core $c tests"
    for i in 1 2 4 6 8 10; do
        echo "Running experiment $i"
        bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/throughput-test/run.sh) -c $c -e 2 -g $i

        echo "Waiting connections for experiment $i"
        sleep $((1*60))

        echo "Waiting for experiment $i to finish"
        sleep $((80))
        for j in $(seq 0 $(($i - 1))); do
            IP=$(docker exec -ti my5grantester$j sh -c "ip -4 addr show uetun1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
            docker exec my5grantester$j sh -c "iperf -c iperf --bind $IP -t 60 -i 1 -y C" > my5grantester-iperf-$c-$i-$j.csv &
        done

        echo "Clear experiment $i environment"
        bash stop_only.sh >/dev/null 2>&1
        docker image prune --filter="dangling=true" >/dev/null 2>&1
        docker volume prune -f >/dev/null 2>&1
    done
done

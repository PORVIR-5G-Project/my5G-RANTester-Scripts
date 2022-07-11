#!/bin/bash

# Check iif filename is provided
if [ $# -eq 0 ]; then
    echo -e "\n Use: $0 /path/to/outputfile.csv \n"
    exit 0
fi

# Get output file name
OUTPUT_FILE=$1

# Check if Nodejs is installed
if ! which node >/dev/null 2>&1; then
    echo "NodeJS is not installed. Installing..."

    curl -s https://deb.nodesource.com/setup_16.x | sudo bash >/dev/null 2>&1
    apt install -y nodejs >/dev/null 2>&1
fi

# Check if NodeJS version is v16.x
if ! node --version | grep v16 >/dev/null 2>&1; then
    echo "NodeJS is installed. Version is not correct. Updating..."

    curl -s https://deb.nodesource.com/setup_16.x | sudo bash >/dev/null 2>&1
    apt install -y nodejs >/dev/null 2>&1
fi

# Capture logs
docker logs my5grantester > /tmp/my5G-RANTester.log

# Download script to parse logs
wget https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/parse_tester_logs.js -O /tmp/parse_tester_logs.js >/dev/null 2>&1

# Parse logs
node /tmp/parse_tester_logs.js /tmp/my5G-RANTester.log $OUTPUT_FILE

# Remove temporary files
rm /tmp/my5G-RANTester.log /tmp/parse_tester_logs.js >/dev/null 2>&1

#!/bin/bash

# Check if filename is provided
if [ $# -eq 0 ]; then
    echo -e "\n Use: $0 outputfile.csv \n"
    exit 0
fi

# Get current directory
WORK_DIR=$(pwd)

# Get output file name
OUTPUT_FILE=$1

# Recreate data directory
rm -rf my5grantester_logs >/dev/null 2>&1
mkdir -p my5grantester_logs
cd my5grantester_logs

# Capture logs
echo "Capturing Docker container logs..."

TESTERS=$(docker ps -a -f name=my5grantester -q)
for tester in $TESTERS; do
    docker logs $tester >> my5grantester_logs.txt
done

# Download scripts to parse logs
echo "Downloading scripts..."
wget https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Logs-Parser/main/index.js -O parse_tester_logs.js >/dev/null 2>&1
wget https://raw.githubusercontent.com/PORVIR-5G-Project/my5G-RANTester-Logs-Parser/main/Dockerfile -O Dockerfile >/dev/null 2>&1

# Parse logs
echo "Parsing logs..."
docker build . -t lando/my5grantester-logs-parser >/dev/null 2>&1
docker run --rm -e INPUT="my5grantester_logs.txt" -e OUTPUT=$OUTPUT_FILE -v $WORK_DIR/my5grantester_logs/:/data lando/my5grantester-logs-parser >/dev/null 2>&1

# Move output file
mv $OUTPUT_FILE $WORK_DIR >/dev/null 2>&1

# Remove temporary files
echo "Cleaning environment..."
cd $WORK_DIR
rm -rf my5grantester_logs >/dev/null 2>&1
docker image rm lando/my5grantester-logs-parser >/dev/null 2>&1

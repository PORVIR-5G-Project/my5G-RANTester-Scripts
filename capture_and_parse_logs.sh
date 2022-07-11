#!/bin/bash

install_nodejs() {
    echo "Installing NodeJS v16..."

    # Remove previous NodeJS version
    apt update >/dev/null 2>&1
    apt remove -y nodejs >/dev/null 2>&1

    # Install NodeJS v16.x
    curl -s https://deb.nodesource.com/setup_16.x | sudo bash >/dev/null 2>&1
    apt install -y nodejs >/dev/null 2>&1
}

# Check iif filename is provided
if [ $# -eq 0 ]; then
    echo -e "\n Use: $0 /path/to/outputfile.csv \n"
    exit 0
fi

# Get output file name
OUTPUT_FILE=$1

# Check if Nodejs is installed
if ! which node >/dev/null 2>&1; then
    echo "NodeJS is not installed."
    install_nodejs
fi

# Check if NodeJS version is v16.x
if ! node --version | grep v16 >/dev/null 2>&1; then
    echo "NodeJS is installed. Version is not correct."
    read -p "Do you want to install NodeJS v16.x (recommended)? [Y/n] " USER_INPUT

    case $USER_INPUT in
        [Nn][Oo] ) ;;
        [Nn] ) ;;
        * ) install_nodejs ;;
    esac
fi

# Capture logs
echo "Capturing Docker container logs..."
docker logs my5grantester > /tmp/my5G-RANTester.log

# Download script to parse logs
wget https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/parse_tester_logs.js -O /tmp/parse_tester_logs.js >/dev/null 2>&1

# Parse logs
echo "Parsing logs..."
node /tmp/parse_tester_logs.js /tmp/my5G-RANTester.log $OUTPUT_FILE

# Remove temporary files
rm /tmp/my5G-RANTester.log /tmp/parse_tester_logs.js >/dev/null 2>&1

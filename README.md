# my5G-RANTester-Scripts
Scripts to run my5G-RANTester

## How to run
1. Install Linux Kernel **v5.4.90** following [this tutorial](https://www.how2shout.com/linux/how-to-change-default-kernel-in-ubuntu-22-04-20-04-lts/).

2. Install `curl`:
    ```bash
    sudo apt update
    ```
    ```bash
    sudo apt -y install curl
    ```

3. Run the `run_all.sh` script:
    ```bash
    sudo -s
    ```
    ```bash
    bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/run_all.sh)
    ```

## How to stop containers and clear data

1. Run the `stop_and_clear.sh` script:
    ```bash
    sudo -s
    ```
    ```bash
    bash <(curl -s https://raw.githubusercontent.com/gabriel-lando/my5G-RANTester-Scripts/main/stop_and_clear.sh)
    ```
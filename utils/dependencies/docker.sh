#!/bin/bash

# Check and install Docker
install_docker(){
    ### Check and install Docker
    if docker compose version | grep "Docker Compose version v2" 2>&1 > /dev/null; then
        print_ok "-> Docker and Docker Compose OK."
    else
        print_warn "-> Docker and/or Docker Compose v2 NOT installed, installing..."
        apt -y remove docker docker.io containerd runc

        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg  --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg

        echo  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        apt update
        apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi

    ### Expose Docker API via TCP
    DOCKER_API_TCP="tcp://0.0.0.0:2375"
    if ! cat /lib/systemd/system/docker.service | grep "$DOCKER_API_TCP" 2>&1 > /dev/null; then
        print "-> Exposing Docker API via TCP at $DOCKER_API_TCP..."

        sed -i "/^ExecStart=/ s|$| -H $DOCKER_API_TCP|" /lib/systemd/system/docker.service

        systemctl daemon-reload
        service docker restart
    fi
}

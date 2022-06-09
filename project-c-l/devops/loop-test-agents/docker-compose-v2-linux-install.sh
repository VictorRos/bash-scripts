#!/usr/bin/env bash

DOCKER_COMPOSE_VERSION=v2.4.1
DOCKER_COMPOSE_SWITCH=v1.0.4

# Install on Linux
echo -e "##### Install on Linux #####"

DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p "${DOCKER_CONFIG}/cli-plugins"

echo -e "\nDownload Docker Compose ${DOCKER_COMPOSE_VERSION}..."
curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o "${DOCKER_CONFIG}/cli-plugins/docker-compose"
echo -e "Docker Compose ${DOCKER_COMPOSE_VERSION} downloaded"

chmod +x "${DOCKER_CONFIG}/cli-plugins/docker-compose"

echo -e "\nCheck Docker Compose is correctly installed"
docker compose version

# Compose Switch
echo -e "\n##### Compose Switch #####"

echo -e "\nDownload & Install Compose Switch..."
sudo curl -fL "https://github.com/docker/compose-switch/releases/download/${DOCKER_COMPOSE_SWITCH}/docker-compose-linux-amd64" -o /usr/local/bin/compose-switch
echo -e "Compose Switch downloaded & installed"

sudo chmod +x /usr/local/bin/compose-switch

echo -e "\nRename old docker-compose to docker-compose-v1"
sudo mv /usr/local/bin/docker-compose /usr/local/bin/docker-compose-v1

echo -e "\nDefine an alternatives group for the docker-compose"
sudo update-alternatives --install /usr/local/bin/docker-compose docker-compose /usr/local/bin/docker-compose-v1 1
sudo update-alternatives --install /usr/local/bin/docker-compose docker-compose /usr/local/bin/compose-switch 99

echo -e "\nVerify your installation"
update-alternatives --display docker-compose

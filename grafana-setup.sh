#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

#Setting up the variables
DOWNLOAD_URL="https://dl.grafana.com/grafana/release/${GRAFANA_VERSION}/grafana_${GRAFANA_VERSION}_36482603486_linux_amd64.deb"
GRAFANA_VERSION="13.2.3"
DEB_FILE= "grafana_${GRAFANA_VERSION}_36482603486_linux_amd64.deb"
GRAFANA_SERVICE="grafana-server"

#Installing necessary dependencies...
sudo apt-get update
sudo apt-get install -y musl adduser libfontconfig1 fontconfig wget

#Downloading Grafana package
wget -c "${DOWNLOAD_URL}" -O "/tmp/${DEB_FILE}"

#Install the downloaded .deb package
sudo dpkg -i "/tmp/${DEB_FILE}"

#Clean up the downloaded file
rm -f "/tmp/${DEB_FILE}"

#Configure Grafana to run as a systemd service
sudo systemctl daemon-reload
sudo systemctl enable "${GRAFANA_SERVICE}".service
sudo systemctl start "${GRAFANA_SERVICE}".service

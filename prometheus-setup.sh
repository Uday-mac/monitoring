#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

#Setting the hostname
echo "prometheus" > /etc/hostname
hostname prometheus

#Setting up the variables
PROM_VERSION="3.13.5"
DOWNLOAD_URL="https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz"
TAR_FILE="prometheus-${PROM_VERSION}.linux-amd64.tar.gz"
EXTRACT_DIR="prometheus-${PROM_VERSION}.linux-amd64"
WORk_DIR="tmp/prom"
CONFIG_DIR="/etc/prometheus"
DATA_DIR="/var/lib/prometheus"
BIN_DIR="/usr/local/bin/"
SERVICE_FILE="/etc/systemd/system/prometheus.service"

#Creating working directory
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

#Downloading the prometheus binary
wget -c "${DOWNLOAD_URL}"

#Untar the downloaded file
tar xzvf "${TAR_FILE}"

#creating user and group for prometheus
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

#creating the config and data directories
mkdir -p "${CONFIG_DIR}"
mkdir -p "${DATA_DIR}"

# Create config subdirectories
mkdir -p "${CONFIG_DIR}/rules"
mkdir -p "${CONFIG_DIR}/rules.s"
mkdir -p "${CONFIG_DIR}/files_sd"

#Moving binaries and configuration files...
cd "${EXTRACT_DIR}"
mv prometheus promtool "${BIN_DIR}"
mv prometheus.yml "${CONFIG_DIR}"

# Create systemd service file
cat > "${SERVICE_FILE}" << EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries \\
  --web.listen-address=0.0.0.0:9090 \\
  --web.enable-remote-write-receiver

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

#Setting file permissions and ownership...
chown -R prometheus:prometheus "${BIN_DIR}"
chmod -R 775 "${BIN_DIR}"
chown -R prometheus:prometheus "${CONFIG_DIR}"
chmod -R 775 "${CONFIG_DIR}"
chown -R prometheus:prometheus "${DATA_DIR}"
chmod -R 775 "${DATA_DIR}"


# Reload and start service
systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
systemctl status prometheus --no-pager
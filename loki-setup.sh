#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

#varibles
VERSION="3.6.19"
DOWNLOAD_URL="https://github.com/grafana/loki/releases/download/v${VERSION}/loki-linux-amd64.zip"
ZIP_FILE="loki-linux-amd64.zip"
BINARY="loki-linux-amd64"
WORK_DIR="/tmp/loki"
CONFIG_DIR="/etc/loki"
DATA_DIR="/var/lib/loki"
BIN_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/loki.service"

#installing unzip
sudo apt-get install zip -y 

#Creating the working directory
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

#downloading the loki 
wget -c "${DOWNLOAD_URL}"
unzip "${ZIP_FILE}"

#moving the binary
mv "${BINARY}" "${BIN_DIR}/loki"
chmod +x "${BIN_DIR}/loki"

#checking the version
loki --version

#creating user and group for loki
groupadd --system loki
useradd --system --no-create-home --shell /sbin/nologin --gid loki loki

# Create data directories
sudo mkdir -p "${DATA_DIR}/chunks" "${DATA_DIR}/rules"
chown -R loki:loki "${DATA_DIR}"
chmod 775 "${DATA_DIR}"

#create config directory
mkdir -p "${CONFIG_DIR}"

# Set ownership for config
sudo chown -R loki:loki "${CONFIG_DIR}"

#create a config file
cat << EOF > "${CONFIG_DIR}/config.yml"
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  log_level: debug
  grpc_server_max_concurrent_streams: 1000

common:
  instance_addr: 127.0.0.1
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

limits_config:
  metric_aggregation_enabled: true
  enable_multi_variant_queries: true

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

pattern_ingester:
  enabled: true
  metric_aggregation:
    loki_address: localhost:3100

ruler:
  alertmanager_url: http://localhost:9093

frontend:
  encoding: protobuf
EOF

# Create systemd service file
sudo cat <<EOF > "${SERVICE_FILE}"
[Unit]
Description=Loki Log Aggregation
After=network.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki --config.file=/etc/loki/config.yml
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Allow firewall port
sudo ufw allow 3100/tcp

# Reload and start service
sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki
sudo systemctl status loki --no-pager

# Wait and verify
sleep 150
curl http://localhost:3100/ready
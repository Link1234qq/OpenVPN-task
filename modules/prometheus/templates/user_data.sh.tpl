#!/bin/bash
set -e

# Update system and install Docker
yum update -y
yum install -y docker

# Start Docker service
systemctl start docker
systemctl enable docker

# Create Prometheus config and storage directory
mkdir -p /opt/prometheus/data
cat > /opt/prometheus/prometheus.yml << 'PROMETHEUS_CONFIG'
${prometheus_config}
PROMETHEUS_CONFIG

# Ensure permissions for Prometheus data directory
chown -R 65534:65534 /opt/prometheus
chmod -R 775 /opt/prometheus

# Run Prometheus container
docker run -d \
  --name prometheus \
  --restart always \
  -p 9090:9090 \
  -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  -v /opt/prometheus/data:/prometheus \
  ${docker_image} \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus

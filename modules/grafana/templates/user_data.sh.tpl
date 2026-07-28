#!/bin/bash
set -e

# Update system and install Docker
yum update -y
yum install -y docker

# Start Docker service
systemctl start docker
systemctl enable docker

# Create Grafana provisioning directories
mkdir -p /opt/grafana/provisioning/datasources
mkdir -p /opt/grafana/provisioning/dashboards

# Create Prometheus datasource config
cat > /opt/grafana/provisioning/datasources/prometheus.yml << 'DATASOURCE_CONFIG'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://${prometheus_ip}:9090
    isDefault: true
    editable: true
DATASOURCE_CONFIG

# Run Grafana container
docker run -d \
  --name grafana \
  --restart always \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD="${grafana_admin_password}" \
  -e GF_INSTALL_PLUGINS=grafana-piechart-panel \
  -v /opt/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:ro \
  -v grafana_data:/var/lib/grafana \
  ${docker_image}

# Wait for Grafana to be ready
sleep 5
docker logs grafana || true

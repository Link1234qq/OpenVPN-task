#!/bin/bash
exec > /var/log/grafana-userdata.log 2>&1
set -x

dnf install -y docker
systemctl enable --now docker

for i in $(seq 1 30); do
  if docker info >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

mkdir -p /opt/grafana/provisioning/datasources
mkdir -p /opt/grafana/provisioning/dashboards

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

docker pull ${docker_image} || docker pull ${docker_image}
docker rm -f grafana 2>/dev/null || true

docker run -d \
  --name grafana \
  --restart always \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD="${grafana_admin_password}" \
  -v /opt/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:ro \
  -v grafana_data:/var/lib/grafana \
  ${docker_image}

sleep 10
docker ps -a
curl -sI http://127.0.0.1:3000/login || true

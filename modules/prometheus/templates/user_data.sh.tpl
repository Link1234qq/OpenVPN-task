#!/bin/bash
exec > /var/log/prometheus-userdata.log 2>&1
set -x

dnf install -y docker
systemctl enable --now docker

for i in $(seq 1 30); do
  if docker info >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

mkdir -p /opt/prometheus/data
cat > /opt/prometheus/prometheus.yml << 'PROMETHEUS_CONFIG'
${prometheus_config}
PROMETHEUS_CONFIG

chown -R 65534:65534 /opt/prometheus
chmod -R 775 /opt/prometheus

docker pull ${docker_image} || docker pull ${docker_image}
docker rm -f prometheus 2>/dev/null || true

docker run -d \
  --name prometheus \
  --restart always \
  -p 9090:9090 \
  -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  -v /opt/prometheus/data:/prometheus \
  ${docker_image} \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus

sleep 10
docker ps -a
curl -sI http://127.0.0.1:9090/-/healthy || true

#!/bin/bash
exec > /var/log/nextcloud-userdata.log 2>&1
set -x

dnf install -y docker
systemctl enable docker
systemctl start docker

echo "Waiting for RDS MySQL on ${db_host}:3306..."
for i in $(seq 1 90); do
  if timeout 2 bash -c "echo >/dev/tcp/${db_host}/3306" 2>/dev/null; then
    echo "RDS is reachable."
    break
  fi
  sleep 10
done

cat > /opt/nextcloud.env <<'ENVEOF'
MYSQL_HOST=${db_host}
MYSQL_DATABASE=${db_name}
MYSQL_USER=${db_user}
MYSQL_PASSWORD=${db_password}
ENVEOF
chmod 600 /opt/nextcloud.env

docker pull ${docker_image}
docker rm -f nextcloud 2>/dev/null || true

docker run -d --name nextcloud --restart unless-stopped \
  -p 80:80 \
  --env-file /opt/nextcloud.env \
  -v nextcloud_data:/var/www/html \
  ${docker_image}

# Start node_exporter for Prometheus metrics
docker rm -f node-exporter 2>/dev/null || true
docker run -d --name node-exporter --restart unless-stopped \
  -p 9100:9100 \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  --net="host" \
  prom/node-exporter:latest \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)

sleep 15
docker ps -a
docker logs nextcloud 2>&1 | tail -50

#!/bin/bash
exec > /var/log/openvpn-userdata.log 2>&1
set -ex

sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker

get_public_ip() {
  local token ip
  token=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)
  if [ -n "$token" ]; then
    ip=$(curl -sf -H "X-aws-ec2-metadata-token: $token" \
      http://169.254.169.254/latest/meta-data/public-ipv4 || true)
  else
    ip=$(curl -sf http://169.254.169.254/latest/meta-data/public-ipv4 || true)
  fi
  echo "$ip"
}

PUBLIC_IP=""
for i in $(seq 1 60); do
  PUBLIC_IP=$(get_public_ip)
  if [ -n "$PUBLIC_IP" ]; then
    break
  fi
  sleep 5
done

if [ -z "$PUBLIC_IP" ]; then
  echo "ERROR: could not resolve Elastic IP (check EIP and IMDSv2)"
  exit 1
fi

echo "Using OpenVPN server public IP: $PUBLIC_IP"

sudo docker rm -f openvpn 2>/dev/null || true
sudo docker volume rm openvpn-data 2>/dev/null || true
sudo docker volume create openvpn-data

sudo docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn \
  ovpn_genconfig -u udp://$PUBLIC_IP -s ${vpn_client_cidr} -r ${vpc_cidr_block} -d

sudo docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn \
  test -f /etc/openvpn/ovpn_env.sh

sudo docker run -v openvpn-data:/etc/openvpn --rm -e EASYRSA_BATCH=1 kylemanna/openvpn \
  ovpn_initpki nopass

sudo docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn \
  easyrsa build-client-full client nopass

sudo docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn \
  ovpn_getclient client | sudo tee /home/ec2-user/client.ovpn > /dev/null

sudo chmod 644 /home/ec2-user/client.ovpn
sudo chown ec2-user:ec2-user /home/ec2-user/client.ovpn
sudo cp /home/ec2-user/client.ovpn /root/client.ovpn

sudo docker run -d --name openvpn --restart unless-stopped \
  -v openvpn-data:/etc/openvpn \
  -p 1194:1194/udp \
  --cap-add=NET_ADMIN \
  kylemanna/openvpn

sudo docker ps -a

echo "OpenVPN ready on udp://$PUBLIC_IP:1194"
echo "Client profile: /home/ec2-user/client.ovpn"

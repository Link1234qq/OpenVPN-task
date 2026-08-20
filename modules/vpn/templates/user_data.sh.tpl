#!/bin/bash
exec > /var/log/openvpn-userdata.log 2>&1
set -ex

sudo dnf install -y docker iptables-services dnsmasq
sudo systemctl enable docker
sudo systemctl start docker

# Clients cannot query the VPC resolver directly: its address sits in the same
# private range as corporate networks, so a more specific route on the client
# steals the traffic. Forwarding through the tunnel address avoids the clash.
# Distro dnsmasq.conf ships bind-interfaces; that option is mutually exclusive
# with bind-dynamic and makes the service refuse to start
sudo sed -i 's/^bind-interfaces/#bind-interfaces/' /etc/dnsmasq.conf

cat <<EOF | sudo tee /etc/dnsmasq.d/vpn.conf
listen-address=${vpn_dns_ip},127.0.0.1
bind-dynamic
no-resolv
server=${vpc_dns_ip}
EOF

echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-ipforward.conf
sudo sysctl -p /etc/sysctl.d/99-ipforward.conf

cat <<'SCRIPT' | sudo tee /usr/local/bin/vpn-nat.sh
#!/bin/bash
set -x
VPN_CIDR="__VPN_CIDR__"
PRIMARY_IF=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
echo "Primary interface: $PRIMARY_IF, VPN CIDR: $VPN_CIDR"

iptables -t nat -C POSTROUTING -s "$VPN_CIDR" -o "$PRIMARY_IF" -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -s "$VPN_CIDR" -o "$PRIMARY_IF" -j MASQUERADE

# Docker sets the FORWARD policy to DROP, so tunnel traffic needs explicit rules
iptables -C FORWARD -s "$VPN_CIDR" -j ACCEPT 2>/dev/null || \
  iptables -I FORWARD 1 -s "$VPN_CIDR" -j ACCEPT
iptables -C FORWARD -d "$VPN_CIDR" -j ACCEPT 2>/dev/null || \
  iptables -I FORWARD 1 -d "$VPN_CIDR" -j ACCEPT

iptables -t nat -L POSTROUTING -n
SCRIPT

sudo sed -i "s|__VPN_CIDR__|${vpn_client_cidr}|" /usr/local/bin/vpn-nat.sh
sudo chmod +x /usr/local/bin/vpn-nat.sh

cat <<'UNIT' | sudo tee /etc/systemd/system/vpn-nat.service
[Unit]
Description=NAT for OpenVPN clients to VPC
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/vpn-nat.sh

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable vpn-nat.service

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

# -p pushes the route to clients; -r would instead add it to the server's own
# routing table, which breaks VPC access from the host under --network host.
# -n points clients at the local dnsmasq, which is the only way they get private
# addresses for internal ALB names
sudo docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn \
  ovpn_genconfig -u udp://$PUBLIC_IP -s ${vpn_client_cidr} -d \
    -p "route ${vpc_route_push}" \
    -p "block-outside-dns" \
    -n ${vpn_dns_ip}

sudo docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn \
  test -f /etc/openvpn/ovpn_env.sh

sudo docker run -v openvpn-data:/etc/openvpn --rm -e EASYRSA_BATCH=1 kylemanna/openvpn \
  ovpn_initpki nopass

sudo docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn \
  easyrsa build-client-full client nopass

sudo docker run -v openvpn-data:/etc/openvpn --rm kylemanna/openvpn \
  ovpn_getclient client | sudo tee /home/ec2-user/client.ovpn > /dev/null

# Windows otherwise keeps using the physical adapter's DNS (corporate/home),
# which cannot resolve internal ALB names. setenv opt keeps unknown clients happy.
sudo tee -a /home/ec2-user/client.ovpn >/dev/null <<EOF

dhcp-option DNS ${vpn_dns_ip}
setenv opt block-outside-dns
EOF

sudo chmod 644 /home/ec2-user/client.ovpn
sudo chown ec2-user:ec2-user /home/ec2-user/client.ovpn
sudo cp /home/ec2-user/client.ovpn /root/client.ovpn

sudo docker run -d --name openvpn --restart unless-stopped \
  --network host \
  -v openvpn-data:/etc/openvpn \
  --cap-add=NET_ADMIN \
  kylemanna/openvpn

sudo systemctl start vpn-nat.service

# Wait until the tunnel address exists, then bind dnsmasq to it
for i in $(seq 1 30); do
  if ip -o -4 addr show | grep -q "${vpn_dns_ip}"; then
    break
  fi
  sleep 1
done

# Failure here must not undo a working VPN
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq || echo "WARN: dnsmasq failed to start"

sudo docker ps -a

echo "OpenVPN ready on udp://$PUBLIC_IP:1194"
echo "Client profile: /home/ec2-user/client.ovpn"

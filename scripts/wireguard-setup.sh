#!/bin/bash
# WireGuard Server Setup Script
# Tested on Ubuntu 20.04/22.04, Debian 11/12

set -e

WG_INTERFACE="wg0"
WG_PORT=51820
CLIENT_NAME="client1"
SERVER_IP=$(curl -s ifconfig.me)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== WireGuard Server Setup ===${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Запустите скрипт с sudo${NC}"
    exit 1
fi

# Install WireGuard
echo -e "${YELLOW}[1/6] Установка WireGuard...${NC}"
apt-get update
apt-get install -y wireguard wireguard-tools qrencode

# Enable IP forwarding
echo -e "${YELLOW}[2/6] Включение IP forwarding...${NC}"
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Generate server keys
echo -e "${YELLOW}[3/6] Генерация ключей сервера...${NC}"
mkdir -p /etc/wireguard/keys
wg genkey | tee /etc/wireguard/keys/server_private.key | wg pubkey > /etc/wireguard/keys/server_public.key

SERVER_PRIVATE_KEY=$(cat /etc/wireguard/keys/server_private.key)
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/keys/server_public.key)

# Create server config
echo -e "${YELLOW}[4/6] Создание конфига сервера...${NC}"
cat > /etc/wireguard/${WG_INTERFACE}.conf <<EOF
[Interface]
Address = 10.200.200.1/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}
PostUp = iptables -A FORWARD -i ${WG_INTERFACE} -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i ${WG_INTERFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

# Generate client keys
echo -e "${YELLOW}[5/6] Генерация ключей клиента...${NC}"
wg genkey | tee /etc/wireguard/keys/${CLIENT_NAME}_private.key | wg pubkey > /etc/wireguard/keys/${CLIENT_NAME}_public.key

CLIENT_PRIVATE_KEY=$(cat /etc/wireguard/keys/${CLIENT_NAME}_private.key)
CLIENT_PUBLIC_KEY=$(cat /etc/wireguard/keys/${CLIENT_NAME}_public.key)

# Add peer to server config
cat >> /etc/wireguard/${WG_INTERFACE}.conf <<EOF

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = 10.200.200.2/32
EOF

# Create client config
echo -e "${YELLOW}[6/6] Создание конфига клиента...${NC}"
mkdir -p /root/client-configs
cat > /root/client-configs/${CLIENT_NAME}.conf <<EOF
[Interface]
Address = 10.200.200.2/24
DNS = 1.1.1.1, 8.8.8.8
PrivateKey = ${CLIENT_PRIVATE_KEY}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
AllowedIPs = 0.0.0.0/0
Endpoint = ${SERVER_IP}:${WG_PORT}
PersistentKeepalive = 20
EOF

# Start WireGuard
echo -e "${GREEN}Запуск WireGuard...${NC}"
wg-quick down ${WG_INTERFACE} 2>/dev/null || true
wg-quick up ${WG_INTERFACE}
systemctl enable wg-quick@${WG_INTERFACE}

echo -e "${GREEN}=== Готово! ===${NC}"
echo -e "Публичный ключ сервера: ${YELLOW}${SERVER_PUBLIC_KEY}${NC}"
echo -e "Конфиг клиента: ${YELLOW}/root/client-configs/${CLIENT_NAME}.conf${NC}"
echo -e "\nQR-код для быстрой настройки на телефоне:"
qrencode -t ansiutf8 < /root/client-configs/${CLIENT_NAME}.conf

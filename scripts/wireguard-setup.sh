#!/bin/bash
# WireGuard Server Setup
# 
# Написал за вечер, когда разбирался как работает WireGuard.
# Скрипт делает всё руками что я делал в первый раз — генерит ключи,
# пишет конфиги, поднимает интерфейс.
#
# Запускать ТОЛЬКО с sudo, иначе не получится трогать /etc/wireguard

set -e  # если какая-то команда упадёт — вылетаем сразу, не продолжаем

WG_INTERFACE="wg0"
WG_PORT=51820
CLIENT_NAME="client1"
SERVER_IP=$(curl -s ifconfig.me)  # узнаём внешний IP сервера

# Цвета для красоты вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== WireGuard Server Setup ===${NC}"

# Проверка рута
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Запусти скрипт с sudo!${NC}"
    exit 1
fi

# 1. Установка WireGuard
echo -e "${YELLOW}[1/6] Ставим WireGuard...${NC}"
apt-get update
apt-get install -y wireguard wireguard-tools qrencode
# qrencode нужен для QR-кода, чтобы телефоном отсканировать конфиг

# 2. Включаем перенаправление пакетов
# Без этого VPN работать не будет — трафик придёт на сервер, но не пойдёт дальше в интернет
echo -e "${YELLOW}[2/6] Включаем IP forwarding...${NC}"
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# 3. Генерация ключей
# WireGuard работает на криптографии с открытым ключом — как SSH
# Приватный ключ остаётся на сервере, публичный можно показывать клиентам
echo -e "${YELLOW}[3/6] Генерируем ключи сервера...${NC}"
mkdir -p /etc/wireguard/keys
wg genkey | tee /etc/wireguard/keys/server_private.key | wg pubkey > /etc/wireguard/keys/server_public.key

SERVER_PRIVATE_KEY=$(cat /etc/wireguard/keys/server_private.key)
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/keys/server_public.key)

# 4. Пишем конфиг сервера
# Address — подсеть для VPN-клиентов. Я взял 10.200.200.x потому что
# 10.0.0.x и 192.168.x.x часто заняты домашними роутерами
echo -e "${YELLOW}[4/6] Пишем конфиг сервера...${NC}"
cat > /etc/wireguard/${WG_INTERFACE}.conf <<EOF
[Interface]
Address = 10.200.200.1/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}
PostUp = iptables -A FORWARD -i ${WG_INTERFACE} -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i ${WG_INTERFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
# PostUp/PostDown — правила iptables, которые добавляются при старте интерфейса
# и убираются при остановке. MASQUERADE маскирует трафик клиентов под IP сервера.

# 5. Ключи клиента
# Пока создаём одного клиента, потом можно добавить ещё через wg set
echo -e "${YELLOW}[5/6] Генерируем ключи клиента...${NC}"
wg genkey | tee /etc/wireguard/keys/${CLIENT_NAME}_private.key | wg pubkey > /etc/wireguard/keys/${CLIENT_NAME}_public.key

CLIENT_PRIVATE_KEY=$(cat /etc/wireguard/keys/${CLIENT_NAME}_private.key)
CLIENT_PUBLIC_KEY=$(cat /etc/wireguard/keys/${CLIENT_NAME}_public.key)

# Добавляем клиента как peer в конфиг сервера
cat >> /etc/wireguard/${WG_INTERFACE}.conf <<EOF

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = 10.200.200.2/32
EOF
# AllowedIPs = 10.200.200.2/32 означает что этому клиенту выдаём только один IP
# Если хочешь чтобы клиент шёл в интернет ЧЕРЕЗ VPN — не трогай это.

# 6. Конфиг для клиента
# Этот файл кидаешь на телефон/компьютер и импортируешь в WireGuard
echo -e "${YELLOW}[6/6] Создаём конфиг клиента...${NC}"
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
# AllowedIPs = 0.0.0.0/0 — ВЕСЬ трафик идёт через VPN
# PersistentKeepalive = 20 — пинг каждые 20 сек, чтобы NAT не закрыл соединение

# Стартуем
echo -e "${GREEN}Запускаем WireGuard...${NC}"
wg-quick down ${WG_INTERFACE} 2>/dev/null || true  # если уже был запущен — гасим
wg-quick up ${WG_INTERFACE}
systemctl enable wg-quick@${WG_INTERFACE}  # чтобы автостарт при перезагрузке

echo -e "${GREEN}=== Готово! ===${NC}"
echo -e "Публичный ключ сервера: ${YELLOW}${SERVER_PUBLIC_KEY}${NC}"
echo -e "Конфиг клиента лежит тут: ${YELLOW}/root/client-configs/${CLIENT_NAME}.conf${NC}"
echo -e "\nQR-код для телефона (отсканируй в приложении WireGuard):"
qrencode -t ansiutf8 < /root/client-configs/${CLIENT_NAME}.conf

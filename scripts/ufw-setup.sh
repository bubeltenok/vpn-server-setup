#!/bin/bash
# UFW Firewall Setup for VPN Server

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== UFW Firewall Setup ===${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Запустите с sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/4] Установка UFW...${NC}"
apt-get update
apt-get install -y ufw

echo -e "${YELLOW}[2/4] Сброс правил...${NC}"
ufw --force reset

echo -e "${YELLOW}[3/4] Настройка правил...${NC}"
# Default deny
ufw default deny incoming
ufw default allow outgoing

# SSH (ограничим по IP в production)
ufw allow 22/tcp comment 'SSH'

# WireGuard
ufw allow 51820/udp comment 'WireGuard'

# OpenVPN
ufw allow 1194/udp comment 'OpenVPN'

# HTTP/HTTPS (если нужен веб-сервер)
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

echo -e "${YELLOW}[4/4] Включение UFW...${NC}"
ufw --force enable

echo -e "${GREEN}=== Статус UFW ===${NC}"
ufw status verbose

echo -e "\n${YELLOW}Совет:${NC} Для дополнительной защиты SSH используйте ssh-hardening.sh"

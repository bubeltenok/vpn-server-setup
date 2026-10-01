#!/bin/bash
# UFW Firewall Setup
#
# UFW — это фаервол.
# Я настроил минимум: SSH, VPN, и всё остальное закрыл.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== UFW Firewall Setup ===${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Только с sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/4] Ставим UFW...${NC}"
apt-get update
apt-get install -y ufw

echo -e "${YELLOW}[2/4] Сбрасываем старые правила...${NC}"
ufw --force reset

echo -e "${YELLOW}[3/4] Настраиваем правила...${NC}"
# По умолчанию — всё закрыто
ufw default deny incoming
ufw default allow outgoing

# SSH — обязательно, иначе потеряешь доступ к серверу
ufw allow 22/tcp comment 'SSH'

# WireGuard
ufw allow 51820/udp comment 'WireGuard'

# OpenVPN
ufw allow 1194/udp comment 'OpenVPN'

# HTTP/HTTPS — если вдруг на сервере будет веб-сервер
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

echo -e "${YELLOW}[4/4] Включаем UFW...${NC}"
ufw --force enable

echo -e "${GREEN}=== Статус ===${NC}"
ufw status verbose

echo -e "\n${YELLOW}Совет:${NC} если менял порт SSH через ssh-hardening.sh — добавь новый порт вручную: ufw allow 2222/tcp"

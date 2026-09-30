#!/bin/bash
# SSH Hardening Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== SSH Hardening ===${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Запустите с sudo${NC}"
    exit 1
fi

# Backup original config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)

echo -e "${YELLOW}[1/5] Отключение root-логина...${NC}"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

echo -e "${YELLOW}[2/5] Отключение парольной аутентификации (только ключи)...${NC}"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

echo -e "${YELLOW}[3/5] Изменение порта (опционально)...${NC}"
read -p "Изменить порт SSH с 22 на 2222? (y/n): " change_port
if [[ $change_port == "y" ]]; then
    sed -i 's/^#\?Port.*/Port 2222/' /etc/ssh/sshd_config
    echo -e "${GREEN}Порт изменен на 2222. Не забудьте открыть его в UFW!${NC}"
fi

echo -e "${YELLOW}[4/5] Ограничение попыток входа...${NC}"
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config

echo -e "${YELLOW}[5/5] Перезапуск SSH...${NC}"
systemctl restart sshd

echo -e "${GREEN}=== Готово ===${NC}"
echo -e "${YELLOW}Важно:${NC} Перед выходом убедитесь, что у вас есть рабочий SSH-ключ!"

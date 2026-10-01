#!/bin/bash
# SSH Hardening
#
# Брутфорс паролей через SSH — самая популярная атака на сервера.
# Я сам ловил тысячи попыток входа в логах в первый же день.
# Этот скрипт закрывает основные дыры.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== SSH Hardening ===${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Только с sudo${NC}"
    exit 1
fi

# Бэкапим оригинальный конфиг на всякий случай
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)

echo -e "${YELLOW}[1/5] Отключаем вход под root...${NC}"
# Root — это бог. Если брутфорсер угадает пароль рута — он получит всё.
# Лучше создать обычного пользователя и давать ему sudo.
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

echo -e "${YELLOW}[2/5] Отключаем парольную аутентификацию...${NC}"
# Только ключи. Пароли подбираются, ключи — нет (если не потерять).
# Перед этим ОБЯЗАТЕЛЬНО закинь свой публичный ключ на сервер!
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

echo -e "${YELLOW}[3/5] Меняем порт SSH (опционально)...${NC}"
read -p "Поменять порт SSH с 22 на 2222? (y/n): " change_port
if [[ $change_port == "y" ]]; then
    sed -i 's/^#\?Port.*/Port 2222/' /etc/ssh/sshd_config
    echo -e "${GREEN}Порт поменял на 2222. Не забудь открыть его в UFW: ufw allow 2222/tcp${NC}"
fi

echo -e "${YELLOW}[4/5] Ограничиваем попытки входа...${NC}"
# После 3 неудачных попыток — disconnect. Замедляет брутфорс.
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config

echo -e "${YELLOW}[5/5] Перезапускаем SSH...${NC}"
systemctl restart sshd

echo -e "${GREEN}=== Готово ===${NC}"
echo -e "${YELLOW}ВАЖНО:${NC} Перед тем как закрыть это окно, проверь что SSH-ключ работает!"
echo -e "Открой НОВОЕ окно терминала и попробуй зайти. Если не пустит — откати бэкап:"
echo -e "cp /etc/ssh/sshd_config.bak.XXX /etc/ssh/sshd_config && systemctl restart sshd"

# VPN Server Setup

Полное руководство по развертыванию VPN-инфраструктуры на собственном Linux-сервере. Поддержка WireGuard и OpenVPN.

## 📋 Что входит

- **WireGuard** — современный, быстрый и простой VPN-протокол
- **OpenVPN** — классический, проверенный временем протокол
- **UFW (Uncomplicated Firewall)** — настройка межсетевого экрана
- **SSH-харднинг** — защита удаленного доступа

## 🚀 Быстрый старт

### 1. WireGuard (рекомендуется)

```bash
chmod +x scripts/wireguard-setup.sh
sudo ./scripts/wireguard-setup.sh
```

Скрипт автоматически:

- Установит WireGuard
- Сгенерирует ключи сервера
- Создаст конфиг сервера
- Настроит IP-форвардинг и NAT
- Добавит первого клиента

### 2. OpenVPN (альтернатива)

```bash
chmod +x scripts/openvpn-setup.sh
sudo ./scripts/openvpn-setup.sh
```

### 3. Настройка фаервола

```bash
chmod +x scripts/ufw-setup.sh
sudo ./scripts/ufw-setup.sh
```

## 📁 Структура проекта

```javascript
vpn-server-setup/
├── configs/              # Конфигурационные файлы
│   ├── wireguard/
│   │   ├── wg0.conf      # Основной конфиг сервера
│   │   └── client1.conf  # Пример конфига клиента
│   └── openvpn/
│       └── server.conf   # Конфиг OpenVPN сервера
├── scripts/              # Bash-скрипты установки
│   ├── wireguard-setup.sh
│   ├── openvpn-setup.sh
│   ├── ufw-setup.sh
│   └── ssh-hardening.sh
├── docker-compose.yml    # Docker-вариант WireGuard
└── README.md
```

## 🔧 Требования

- Сервер на Ubuntu 20.04+ / Debian 10+
- Root-доступ (sudo)
- Открытый UDP-порт 51820 (WireGuard) или 1194 (OpenVPN)

## 📜 Лицензия

MIT — используй свободно.
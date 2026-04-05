#!/bin/bash

# =========================
# COLORES PRO
# =========================
GREEN="\e[1;32m"
ORANGE="\e[1;33m"
BLUE="\e[1;34m"
RED="\e[1;31m"
CYAN="\e[1;36m"
RESET="\e[0m"

# =========================
# FUNCIONES UI
# =========================
loading() {
    echo -ne "${ORANGE}⏳ $1${RESET}"
    for i in {1..4}; do
        echo -ne "${ORANGE}.${RESET}"
        sleep 0.4
    done
    echo ""
}

ok() {
    echo -e "${GREEN}✔ $1${RESET}"
}

info() {
    echo -e "${BLUE}➜ $1${RESET}"
}

error() {
    echo -e "${RED}✖ $1${RESET}"
}

# =========================
# HEADER PANEL PRO
# =========================
clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║        🚀 DNS PANEL ADMIN PRO        ║"
echo "║        AdGuard + Unbound Setup       ║"
echo "╚══════════════════════════════════════╝"
echo -e "${RESET}"

sleep 1

# =========================
# VARIABLES
# =========================
HOSTNAME="nexoserver-1"

# =========================
# SISTEMA
# =========================
loading "Actualizando sistema"
apt update -y && apt upgrade -y >/dev/null 2>&1 && ok "Sistema actualizado"

# =========================
# HOSTNAME
# =========================
loading "Configurando hostname"
hostnamectl set-hostname $HOSTNAME

if ! grep -q "$HOSTNAME" /etc/hosts; then
    echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
fi

ok "Hostname aplicado: $HOSTNAME"

# =========================
# DEPENDENCIAS
# =========================
loading "Instalando dependencias"
apt install -y wget curl unbound dnsutils >/dev/null 2>&1 && ok "Dependencias listas"

# =========================
# ADGUARD
# =========================
loading "Instalando AdGuard Home"

cd /opt
rm -rf AdGuardHome

wget -q https://static.adguard.com/adguardhome/release/AdGuardHome_linux_amd64.tar.gz
tar -xvf AdGuardHome_linux_amd64.tar.gz >/dev/null 2>&1
cd AdGuardHome

./AdGuardHome -s install >/dev/null 2>&1

ok "AdGuard instalado correctamente"

# =========================
# UNBOUND
# =========================
loading "Configurando Unbound"

mv /etc/unbound/unbound.conf /etc/unbound/unbound.conf.bak 2>/dev/null

cat <<EOF > /etc/unbound/unbound.conf
server:
interface: 127.0.0.1
port: 5335
verbosity: 1
do-ip4: yes
do-udp: yes
do-tcp: yes
EOF

if unbound-checkconf >/dev/null 2>&1; then
    ok "Configuración válida"
else
    error "Error en configuración"
fi

systemctl daemon-reexec
systemctl enable unbound >/dev/null 2>&1
systemctl restart unbound

ok "Unbound activo"

# =========================
# FIREWALL
# =========================
if command -v ufw >/dev/null 2>&1; then
    loading "Aplicando reglas firewall"
    ufw allow 53 >/dev/null
    ufw allow 80 >/dev/null
    ufw allow 443 >/dev/null
    ufw allow 5335 >/dev/null
    ok "Firewall listo"
fi

# =========================
# IP PUBLICA
# =========================
loading "Detectando IP pública"
IP=$(curl -s ifconfig.me)
ok "IP: $IP"

# =========================
# TEST
# =========================
loading "Test DNS (Unbound)"
dig @127.0.0.1 -p 5335 google.com +short

# =========================
# PANEL FINAL
# =========================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗"
echo -e "║          ✔ SISTEMA OPERATIVO         ║"
echo -e "╚══════════════════════════════════════╝${RESET}"

echo -e "${BLUE}🌐 Acceso al panel:${RESET}"
echo -e "${GREEN}   http://$IP${RESET}"
echo ""

echo -e "${BLUE}⚙️ Configuración recomendada:${RESET}"
echo -e "${GREEN}   Upstream DNS → 127.0.0.1:5335${RESET}"
echo ""

echo -e "${GREEN}🔥 DNS ACTIVO - LISTO PARA PRODUCCIÓN 🔥${RESET}"
echo ""

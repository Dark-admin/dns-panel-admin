#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# DNS Panel Admin Pro - safer installer for AdGuard Home + Unbound
# Compatible with Debian/Ubuntu systems.

GREEN="\e[1;32m"
ORANGE="\e[1;33m"
BLUE="\e[1;34m"
RED="\e[1;31m"
CYAN="\e[1;36m"
RESET="\e[0m"

HOSTNAME_VALUE="${HOSTNAME_VALUE:-nexoserver-1}"
UNBOUND_PORT="${UNBOUND_PORT:-5335}"
ADGUARD_DIR="${ADGUARD_DIR:-/opt/AdGuardHome}"
BACKUP_DIR="${BACKUP_DIR:-/root/dns-panel-admin-backups}"
DO_UPGRADE="${DO_UPGRADE:-0}"
OPEN_WEB_PORTS="${OPEN_WEB_PORTS:-1}"
OPEN_DNS_PORT="${OPEN_DNS_PORT:-1}"
OPEN_UNBOUND_PORT="${OPEN_UNBOUND_PORT:-0}"
INSTALL_CHANNEL="${INSTALL_CHANNEL:-release}"

log() { echo -e "${BLUE}➜${RESET} $*"; }
ok() { echo -e "${GREEN}✔${RESET} $*"; }
warn() { echo -e "${ORANGE}⚠${RESET} $*"; }
fail() { echo -e "${RED}✖${RESET} $*" >&2; exit 1; }

on_error() {
    local line="$1"
    fail "Error en la línea ${line}. Revisa los mensajes anteriores."
}
trap 'on_error $LINENO' ERR

usage() {
    cat <<'EOF'
DNS Panel Admin Pro

Uso:
  sudo ./dns-panel.sh [opciones]

Opciones:
  --hostname NOMBRE        Hostname del servidor (default: nexoserver-1)
  --unbound-port PUERTO    Puerto local de Unbound (default: 5335)
  --upgrade                Ejecuta apt upgrade además de apt update
  --no-open-web            No abre puertos 80/443 en UFW
  --no-open-dns            No abre puerto 53 en UFW
  --open-unbound           Abre el puerto de Unbound en UFW (no recomendado)
  --help                   Muestra esta ayuda

Variables de entorno útiles:
  HOSTNAME_VALUE, UNBOUND_PORT, ADGUARD_DIR, BACKUP_DIR, DO_UPGRADE,
  OPEN_WEB_PORTS, OPEN_DNS_PORT, OPEN_UNBOUND_PORT, INSTALL_CHANNEL
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --hostname)
            HOSTNAME_VALUE="${2:-}"
            [[ -n "$HOSTNAME_VALUE" ]] || fail "--hostname requiere un valor"
            shift 2
            ;;
        --unbound-port)
            UNBOUND_PORT="${2:-}"
            [[ "$UNBOUND_PORT" =~ ^[0-9]+$ ]] || fail "--unbound-port requiere un número"
            shift 2
            ;;
        --upgrade)
            DO_UPGRADE=1
            shift
            ;;
        --no-open-web)
            OPEN_WEB_PORTS=0
            shift
            ;;
        --no-open-dns)
            OPEN_DNS_PORT=0
            shift
            ;;
        --open-unbound)
            OPEN_UNBOUND_PORT=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            fail "Opción desconocida: $1"
            ;;
    esac
done

require_root() {
    [[ "${EUID}" -eq 0 ]] || fail "Ejecuta como root: sudo $0"
}

require_supported_os() {
    [[ -r /etc/os-release ]] || fail "No se pudo detectar el sistema operativo"
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
        debian|ubuntu) ;;
        *)
            case "${ID_LIKE:-}" in
                *debian*) ;;
                *) fail "Sistema no soportado: ${PRETTY_NAME:-desconocido}. Usa Debian/Ubuntu." ;;
            esac
            ;;
    esac
}

arch_suffix() {
    case "$(uname -m)" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l|armhf) echo "armv7" ;;
        *) fail "Arquitectura no soportada por este instalador: $(uname -m)" ;;
    esac
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "Comando requerido no encontrado: $1"
}

backup_file() {
    local file="$1"
    [[ -e "$file" ]] || return 0
    mkdir -p "$BACKUP_DIR"
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    cp -a "$file" "$BACKUP_DIR/$(basename "$file").$stamp.bak"
    ok "Respaldo creado: $BACKUP_DIR/$(basename "$file").$stamp.bak"
}

print_header() {
    clear || true
    echo -e "${CYAN}"
    cat <<'EOF'
██████╗ ███╗   ██╗███████╗
██╔══██╗████╗  ██║██╔════╝
██║  ██║██╔██╗ ██║███████╗
██║  ██║██║╚██╗██║╚════██║
██████╔╝██║ ╚████║███████║
╚═════╝ ╚═╝  ╚═══╝╚══════╝
EOF
    echo -e "${RESET}"
    echo "╔══════════════════════════════════════╗"
    echo "║        DNS PANEL ADMIN PRO           ║"
    echo "║        AdGuard + Unbound Setup       ║"
    echo "╚══════════════════════════════════════╝"
    echo ""
}

install_packages() {
    export DEBIAN_FRONTEND=noninteractive
    log "Actualizando índice de paquetes"
    apt-get update -y

    if [[ "$DO_UPGRADE" == "1" ]]; then
        warn "Ejecutando apt upgrade porque se solicitó --upgrade"
        apt-get upgrade -y
    else
        ok "Saltando apt upgrade para evitar cambios grandes no solicitados"
    fi

    log "Instalando dependencias"
    apt-get install -y ca-certificates wget curl tar unbound dnsutils
    ok "Dependencias instaladas"
}

configure_hostname() {
    [[ -n "$HOSTNAME_VALUE" ]] || return 0
    log "Configurando hostname: $HOSTNAME_VALUE"
    hostnamectl set-hostname "$HOSTNAME_VALUE"

    if ! grep -Eq "[[:space:]]${HOSTNAME_VALUE}([[:space:]]|$)" /etc/hosts; then
        backup_file /etc/hosts
        printf '127.0.1.1 %s\n' "$HOSTNAME_VALUE" >> /etc/hosts
    fi
    ok "Hostname aplicado"
}

install_adguard() {
    local arch url tmpdir archive
    arch="$(arch_suffix)"
    url="https://static.adguard.com/adguardhome/${INSTALL_CHANNEL}/AdGuardHome_linux_${arch}.tar.gz"
    tmpdir="$(mktemp -d)"
    archive="$tmpdir/AdGuardHome.tar.gz"

    log "Instalando/actualizando AdGuard Home (${arch})"
    wget -qO "$archive" "$url"
    tar -xzf "$archive" -C "$tmpdir"

    if systemctl list-unit-files | grep -q '^AdGuardHome.service'; then
        systemctl stop AdGuardHome || true
    fi

    if [[ -d "$ADGUARD_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        local stamp
        stamp="$(date +%Y%m%d-%H%M%S)"
        tar -czf "$BACKUP_DIR/AdGuardHome.$stamp.tar.gz" -C "$(dirname "$ADGUARD_DIR")" "$(basename "$ADGUARD_DIR")"
        ok "Respaldo de AdGuard creado: $BACKUP_DIR/AdGuardHome.$stamp.tar.gz"
    fi

    mkdir -p "$(dirname "$ADGUARD_DIR")"
    rm -rf "$ADGUARD_DIR.new"
    mv "$tmpdir/AdGuardHome" "$ADGUARD_DIR.new"

    if [[ -f "$ADGUARD_DIR/AdGuardHome.yaml" ]]; then
        cp -a "$ADGUARD_DIR/AdGuardHome.yaml" "$ADGUARD_DIR.new/AdGuardHome.yaml"
    fi

    rm -rf "$ADGUARD_DIR"
    mv "$ADGUARD_DIR.new" "$ADGUARD_DIR"
    "$ADGUARD_DIR/AdGuardHome" -s install >/dev/null 2>&1 || "$ADGUARD_DIR/AdGuardHome" -s start >/dev/null 2>&1
    systemctl enable --now AdGuardHome >/dev/null 2>&1 || true

    rm -rf "$tmpdir"
    ok "AdGuard Home instalado"
}

configure_unbound() {
    log "Configurando Unbound en 127.0.0.1:${UNBOUND_PORT}"
    mkdir -p /etc/unbound/unbound.conf.d
    backup_file /etc/unbound/unbound.conf

    cat >/etc/unbound/unbound.conf <<EOF
include: "/etc/unbound/unbound.conf.d/*.conf"
EOF

    cat >/etc/unbound/unbound.conf.d/dns-panel-admin.conf <<EOF
server:
    interface: 127.0.0.1
    port: ${UNBOUND_PORT}
    access-control: 127.0.0.0/8 allow
    do-ip4: yes
    do-ip6: no
    do-udp: yes
    do-tcp: yes
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    prefetch: yes
    qname-minimisation: yes
    minimal-responses: yes
    cache-min-ttl: 300
    cache-max-ttl: 86400
    verbosity: 1
EOF

    unbound-checkconf
    systemctl enable --now unbound
    systemctl restart unbound
    ok "Unbound activo y validado"
}

configure_firewall() {
    command -v ufw >/dev/null 2>&1 || { warn "UFW no instalado; saltando reglas firewall"; return 0; }

    log "Aplicando reglas UFW seguras"
    if [[ "$OPEN_DNS_PORT" == "1" ]]; then
        ufw allow 53/tcp comment 'DNS TCP - AdGuard Home' >/dev/null || true
        ufw allow 53/udp comment 'DNS UDP - AdGuard Home' >/dev/null || true
    fi

    if [[ "$OPEN_WEB_PORTS" == "1" ]]; then
        ufw allow 80/tcp comment 'HTTP - AdGuard Home' >/dev/null || true
        ufw allow 443/tcp comment 'HTTPS - AdGuard Home' >/dev/null || true
        ufw allow 3000/tcp comment 'AdGuard initial setup' >/dev/null || true
    fi

    if [[ "$OPEN_UNBOUND_PORT" == "1" ]]; then
        warn "Abriendo Unbound al firewall; no recomendado salvo que sepas lo que haces"
        ufw allow "${UNBOUND_PORT}/tcp" comment 'Unbound TCP' >/dev/null || true
        ufw allow "${UNBOUND_PORT}/udp" comment 'Unbound UDP' >/dev/null || true
    else
        ufw deny "${UNBOUND_PORT}" >/dev/null 2>&1 || true
        ok "Unbound queda solo local; puerto ${UNBOUND_PORT} no se expone"
    fi
    ok "Reglas firewall aplicadas"
}

public_ip() {
    curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'
}

run_tests() {
    log "Probando resolución DNS local con Unbound"
    if dig @127.0.0.1 -p "$UNBOUND_PORT" google.com +short +time=3 +tries=1 | grep -Eq '^[0-9a-fA-F:.]+$'; then
        ok "Unbound responde correctamente"
    else
        warn "No se pudo confirmar respuesta DNS de Unbound. Revisa: systemctl status unbound"
    fi
}

final_message() {
    local ip
    ip="$(public_ip || true)"
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════╗"
    echo -e "║             INSTALACIÓN LISTA        ║"
    echo -e "╚══════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BLUE}Panel / asistente inicial:${RESET} ${GREEN}http://${ip}:3000${RESET}"
    echo -e "${BLUE}Panel final usual:${RESET}      ${GREEN}http://${ip}${RESET}"
    echo ""
    echo -e "${ORANGE}Configura en AdGuard:${RESET}"
    echo -e "${GREEN}Upstream DNS → 127.0.0.1:${UNBOUND_PORT}${RESET}"
    echo ""
    echo -e "${ORANGE}Seguridad:${RESET} Unbound escucha solo en 127.0.0.1 y no se expone al firewall."
    echo -e "${ORANGE}Respaldos:${RESET} $BACKUP_DIR"
    echo ""
}

main() {
    print_header
    require_root
    require_supported_os
    need_cmd apt-get
    need_cmd systemctl
    install_packages
    configure_hostname
    install_adguard
    configure_unbound
    configure_firewall
    run_tests
    final_message
}

main "$@"

# 🚀 DNS Panel Admin Pro

Instalador Bash para desplegar un servidor DNS con:

- 🛡️ **AdGuard Home** para panel web, bloqueo de anuncios y control DNS
- ⚡ **Unbound** como resolver DNS local privado
- 🔐 Configuración más segura por defecto

> Compatible con VPS/servidores **Ubuntu/Debian**.

---

## ✅ Mejoras incluidas

- Validación de **root**, sistema operativo y arquitectura
- Instalación compatible con `amd64`, `arm64` y `armv7`
- `apt upgrade` ya **no se ejecuta por defecto** para evitar cambios grandes no pedidos
- Respaldos automáticos antes de modificar archivos importantes
- Unbound escucha solo en `127.0.0.1:5335`
- Unbound **no se expone al firewall** por defecto
- Reglas UFW más específicas: TCP/UDP donde corresponde
- Configuración Unbound endurecida: DNSSEC hardening, privacidad, cache y minimización QNAME
- Parámetros configurables por flags o variables de entorno
- Mejor manejo de errores con `set -Eeuo pipefail`

---

## 📦 Requisitos

- Ubuntu/Debian
- Acceso root/sudo
- Conexión a internet

---

## 🚀 Instalación rápida

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/Dark-admin/dns-panel-admin/main/dns-panel.sh)
```

---

## 🖥️ Instalación manual

```bash
git clone https://github.com/Dark-admin/dns-panel-admin.git
cd dns-panel-admin
chmod +x dns-panel.sh
sudo ./dns-panel.sh
```

---

## ⚙️ Opciones

```bash
sudo ./dns-panel.sh [opciones]
```

| Opción | Descripción |
|---|---|
| `--hostname NOMBRE` | Cambia el hostname del servidor. Default: `nexoserver-1` |
| `--unbound-port PUERTO` | Puerto local de Unbound. Default: `5335` |
| `--upgrade` | Ejecuta `apt upgrade` además de `apt update` |
| `--no-open-web` | No abre puertos `80`, `443` ni `3000` en UFW |
| `--no-open-dns` | No abre puerto DNS `53` en UFW |
| `--open-unbound` | Abre el puerto de Unbound en UFW. **No recomendado** |
| `--help` | Muestra ayuda |

También puedes usar variables de entorno:

```bash
HOSTNAME_VALUE=dns-server UNBOUND_PORT=5335 sudo -E ./dns-panel.sh
```

---

## 🌐 Acceso al panel

Al terminar, abre el asistente inicial de AdGuard Home:

```text
http://TU-IP:3000
```

Después del setup, normalmente usarás:

```text
http://TU-IP
```

---

## ⚙️ Configuración en AdGuard

En el asistente o en la configuración de AdGuard, usa como upstream DNS:

```text
127.0.0.1:5335
```

Arquitectura:

```text
Cliente → AdGuard Home :53 → Unbound 127.0.0.1:5335 → Internet
```

---

## 🔐 Puertos

| Puerto | Uso | Expuesto por defecto |
|---|---|---|
| `53/tcp` y `53/udp` | DNS de AdGuard Home | Sí |
| `80/tcp` | Panel web HTTP | Sí |
| `443/tcp` | Panel web HTTPS si lo configuras | Sí |
| `3000/tcp` | Asistente inicial de AdGuard | Sí |
| `5335/tcp/udp` | Unbound local | **No** |

> Unbound debe quedarse local. Exponer `5335` públicamente puede convertir tu servidor en un resolver abierto.

---

## 🧪 Verificación

Prueba Unbound:

```bash
dig @127.0.0.1 -p 5335 google.com +short
```

Estado de servicios:

```bash
systemctl status AdGuardHome
systemctl status unbound
```

Ver firewall:

```bash
sudo ufw status verbose
```

---

## 🧯 Respaldos

El script guarda respaldos en:

```text
/root/dns-panel-admin-backups
```

Incluye respaldos de configuración y de instalaciones previas de AdGuard Home cuando existen.

---

## 👨‍💻 Autor

Dark-admin

---

## ⭐ Recomendación

Si te sirve, dale una estrella al proyecto y adáptalo a tu servidor antes de usarlo en producción.

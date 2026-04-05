# 🚀 DNS PANEL ADMIN PRO

Panel de instalación automática en Bash para desplegar un servidor DNS profesional usando:

* 🛡️ AdGuard Home (bloqueo de anuncios y control DNS)
* ⚡ Unbound (resolver DNS local seguro)
* 🎛️ Interfaz tipo panel en terminal (CLI PRO)

---

## 🔥 Características

✔ Instalación completamente automática
✔ Configuración optimizada de DNS
✔ Integración AdGuard + Unbound
✔ Panel visual con colores (modo profesional)
✔ Test automático de funcionamiento
✔ Compatible con VPS (Ubuntu/Debian)

---

## ⚙️ Componentes

### 🧩 AdGuard Home

* Panel web de administración DNS
* Bloqueo de publicidad y trackers
* Control de tráfico DNS

### ⚡ Unbound

* Resolver DNS local (127.0.0.1:5335)
* Mayor privacidad
* Sin dependencia de DNS externos

---

## 🚀 Instalación rápida

Ejecuta en tu servidor:

```bash
bash <(curl -s https://raw.githubusercontent.com/Dark-admin/dns-panel-admin/main/dns-panel.sh)
```

---

## 🖥️ Instalación manual

```bash
git clone https://github.com/Dark-admin/dns-panel-admin.git
cd dns-panel-admin
chmod +x dns-panel.sh
./dns-panel.sh
```

---

## 🌐 Acceso al panel

Después de la instalación:

```
http://TU-IP
```

---

## ⚙️ Configuración en AdGuard

Configura el DNS upstream:

```
127.0.0.1:5335
```

---

## 🧪 Verificación

El script incluye prueba automática:

```bash
dig @127.0.0.1 -p 5335 google.com +short
```

---

## 🔐 Puertos utilizados

* 53 → DNS
* 80 → Panel web
* 443 → HTTPS (opcional)
* 5335 → Unbound

---

## 📦 Requisitos

* Ubuntu / Debian
* Acceso root
* Conexión a internet

---

## 🧠 Arquitectura

```
Cliente → AdGuard → Unbound → Internet
```

---

## 🔥 Estado del sistema

Al finalizar verás:

* ✔ AdGuard instalado
* ✔ Unbound activo
* ✔ DNS funcionando

---

## 🚀 Futuras mejoras

* 🔐 SSL automático (Let's Encrypt)
* 🎛️ Menú interactivo
* 📊 Dashboard en tiempo real
* 🌍 Soporte para dominios personalizados

---

## 👨‍💻 Autor

Dark-admin

---

## ⭐ Recomendación

Si te gusta este proyecto:

👉 Dale una estrella en GitHub
👉 Úsalo en producción
👉 Mejora tu privacidad DNS

---

🔥 **DNS rápido, seguro y profesional en minutos**


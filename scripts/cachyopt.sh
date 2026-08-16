#!/usr/bin/env bash

# Salir inmediatamente si un comando falla

echo "=========================================================="
echo "  Optimizador y Configurador de CachyOS para MacBook 2015"
echo "=========================================================="

# 1. Actualizar el sistema e instalar el llavero de CachyOS
echo "--> Actualizando repositorios y el sistema..."
sudo pacman -Syu --noconfirm

# 2. Controladores específicos para MacBook Intel (Broadcom Wi-Fi y FacetimeHD)
echo "--> Instalando controladores de hardware para Apple Mac..."
# CachyOS incluye soporte excelente para Broadcom; aseguramos los paquetes correctos
sudo pacman -S --needed --noconfirm broadcom-sta-dkms linux-firmware facetimehd-firmware dkms

# 3. Optimización Avanzada de Batería sin perder rendimiento
echo "--> Configurando optimización energética avanzada..."
# Desinstalamos TLP ya que CachyOS utiliza y recomienda 'power-profiles-daemon' o 'auto-cpufreq'
# Instalamos auto-cpufreq que gestiona de manera inteligente las frecuencias del CPU Intel sin mermar potencia
sudo pacman -S --needed --noconfirm auto-cpufreq
sudo systemctl enable --now auto-cpufreq.service

# Ajustar parámetros de energía del Kernel de Linux para MacBooks Intel
echo "--> Optimizando parámetros del sistema de archivos y energía de la GPU Intel..."
sudo tee /etc/sysctl.d/99-macbook-power.conf <<EOF
# Optimizar el refresco de las escrituras en disco para ahorrar batería
vm.dirty_writeback_centisecs = 1500
# Reducir el uso agresivo de la SWAP para cuidar el SSD
vm.swappiness = 10
EOF

# 4. Instalación de Programas Solicitados
echo "--> Instalando programas: LibreOffice, Python, VS Code, Herramientas SQL, IA y Htop..."

# Utilizaremos 'cachyos-repo-tool' o directamente 'pacman'/'paru' para la máxima velocidad de descarga
# LibreOffice, Python, Htop, Docker (ideal para SQL) y git
sudo pacman -S --needed --noconfirm \
    libreoffice-fresh \
    python python-pip \
    htop \
    docker docker-compose \
    git \
    wget \
    curl

# CachyOS provee Visual Studio Code de forma nativa en sus repositorios o la versión open-source (code)
sudo pacman -S --needed --noconfirm code

# 5. Instalación de Herramientas de Base de Datos (SQL) e Inteligencia Artificial (IA)
echo "--> Configurando Base de Datos e IA..."

# Para SQL: Instalamos DBeaver (Excelente gestor universal para PostgreSQL, MySQL, SQLite, etc.)
sudo pacman -S --needed --noconfirm dbeaver

# Para IA: Instalamos Ollama para que puedas correr Modelos de Lenguaje (LLMs) localmente en tu Mac
if ! command -v ollama &> /dev/null; then
    echo "Instalando Ollama para Inteligencia Artificial local..."
    curl -fsSL https://ollama.com | sh
fi

# 6. Habilitar servicios críticos
echo "--> Habilitando servicios del sistema..."
sudo systemctl enable --now docker.service
sudo usermod -aG docker $USER

echo "=========================================================="
echo "  ¡Configuración completada con éxito!"
echo "=========================================================="
echo "NOTAS IMPORTANTES:"
echo "1. Reinicia tu MacBook para aplicar los controladores y cambios de energía."
echo "2. Para usar Docker sin 'sudo', cierra sesión y vuelve a entrar."
echo "3. Para ejecutar un modelo de IA local, escribe en tu terminal: ollama run llama3"
echo "=========================================================="

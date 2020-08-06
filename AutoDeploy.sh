#!/bin/bash

# Colores - @s4vitar
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Variables globales
SCRIPT_PATH="$(pwd)"
FILES_PATH="$SCRIPT_PATH/files"

# Funciones
function info {
	echo -e "${greenColour}[${turquoiseColour}*${greenColour}] ${grayColour}$1${endColour}"
}

function question {
	input=""
	while [ "$input" == "" ]; do
		echo -ne "${turquoiseColour}[${purpleColour}?${turquoiseColour}] ${grayColour}$1: ${endColour}" && read input
	done
}

function yes_or_no {
	echo -ne "${turquoiseColour}[${purpleColour}?${turquoiseColour}] ${grayColour}$1 ${turquoiseColour}(${greenColour}Y${grayColour}/${redColour}n${turquoiseColour})${grayColour}: ${endColour}" && read input
	case "$input" in
		n|N) input=0;;
		*) input=1;;
	esac
}

function error {
	echo -e "${redColour}[!] $1${endColour}"
	echo -e "[$(date +%T)] $1" 2>/dev/null >> $SCRIPT_PATH/error.log
}

function check {
	if [ $? -ne 0 ]; then error "$1"; fi
}

function section {
	echo -e "\n${turquoiseColour}[${greenColour}+${turquoiseColour}] ${greenColour}$1${endColour}"
}

function exit_handler {
	echo -e "\n${redColour}[-] Cerrando instalador${endColour}\n"
	tput cnorm
	exit
}


##################################################
# INICIALIZACIÓN                                 #
##################################################

trap "exit_handler" SIGINT SIGTERM

if [ ! -d "files/" ]; then
	echo -e "\n[!] Ejecuta este script desde la carpeta de AutoDeploy para evitar errores\n"
	exit 1
fi

echo -e "$yellowColour"
cat $FILES_PATH/banner.txt
echo -e "$endColour"

if [ "$EUID" -ne 0 ]; then
	error "Este script debe ser ejecutado por r00t!\n"
	exit 1
fi

rm -f $SCRIPT_PATH/error.log 2>/dev/null

question "Hostname"
HOSTNAME=$input
question "Nombre de usuario ($(ls /home | xargs | tr ' ' ','))"
USERNAME=$input
HOME_PATH="/home/$USERNAME"
if [ ! -d "$HOME_PATH" ]; then
	error "El directorio home del usuario no existe (/home/$USERNAME)"
	exit 1
fi

if cat /proc/cpuinfo | grep "hypervisor" > /dev/null 2>&1 ; then
	info "Se ha detectado que el SO corre en una VM. La configuración gráfica puede ser exhaustiva en estos entornos."
	yes_or_no "¿Instalar gráficos menos intensivos?"
	IS_VM=$input
else
	yes_or_no "¿Ordenador portátil?"
	IS_LAPTOP=$input
fi

WALLPAPER_PATH="$FILES_PATH/wallpaper.png"
if [ ! -f "$WALLPAPER_PATH" ]; then
	error "Fondo de pantalla no encontrado - $FILES_PATH/wallpaper.png"
	exit 1
fi

section "COMENZANDO INSTALACIÓN"
tput civis
info "Comprobando resolución DNS"
host www.google.com > /dev/null 2>&1
if [ $? -ne 0 ]; then
	error "Fallo en la resolución DNS - no se pudo resolver www.google.com"
	exit 1
fi

info "Actualizando repositorios"
apt update > /dev/null 2>&1


##################################################
# INSTALACIÓN DE UTILIDADES                      #
##################################################

section "Instalación de utilidades"

# Instalación de utilidades
info "Instalando paquetes de utilidad"
apt install -y python-pip php-curl snmp passing-the-hash enum4linux ranger htop ghex cherrytree nfs-common cifs-utils ldap-utils xclip feh exploitdb scrub i3lock bashtop cmatrix figlet lolcat sl scrot rinetd rlwrap knockd trash-cli gcc-multilib crackmapexec micro rofi > /dev/null 2>&1
check "No se pudieron instalar paquetes de herramientas básicas"
# Sí, el lolcat es básico .- .

# Instalación de scripts
info "Instalando scripts Bash varios"
chmod +x $FILES_PATH/scripts/* 2>/dev/null
check "No se pudieron dar permisos de ejecución a $FILES_PATH/scripts/*"
chown root:root $FILES_PATH/scripts/* 2>/dev/null
cp -r $FILES_PATH/scripts/* /usr/local/bin 2>/dev/null
check "No se encontró $FILES_PATH/scripts/"

# Google Chrome
info "Instalando Google Chrome"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb > /dev/null 2>&1
check "No se pudo decargar Google Chrome - https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
dpkg -i /tmp/chrome.deb > /dev/null 2>&1
check "Error en la instalación de Google Chrome"

# Postman
info "Instalando Postman"
wget https://dl.pstmn.io/download/latest/linux64 -O /tmp/postman.tar.gz > /dev/null 2>&1
check "No se pudo descargar Postman - https://dl.pstmn.io/download/latest/linux64"
tar -C /opt -zxvf /tmp/postman.tar.gz > /dev/null 2>&1
check "No se pudo descomprimir Postman"
ln -sf /opt/Postman/app/Postman /usr/local/bin/Postman 2>/dev/null

# Stegsolve
info "Instalando StegSolve"
wget http://www.caesum.com/handbook/Stegsolve.jar -O /opt/stegsolve.jar > /dev/null 2>&1
check "No se pudo descargar StegSolve - http://www.caesum.com/handbook/Stegsolve.jar"
chmod +x /opt/stegsolve.jar 2>/dev/null

# Gotop
info "Instalando Gotop"
git clone --depth 1 https://github.com/cjbassi/gotop /tmp/gotop > /dev/null 2>&1
check "No se pudo clonar el repositorio de Gotop"
/tmp/gotop/scripts/download.sh > /dev/null 2>&1
check "Error en la instalación de Gotop"
mv gotop /usr/local/bin 2>/dev/null
check "No se pudo mover el binario de gotop a /usr/local/bin"

# Updog
info "Instalando updog"
pip3 install updog > /dev/null 2>&1
check "Error instalando updog (root)"
sudo -u $USERNAME pip3 install updog > /dev/null 2>&1
check "Error instalando updog ($USERNAME)"

# pwn
info "Instalando pwn"
pip install pwn > /dev/null 2>&1
check "Error instalando pwn (root)"
sudo -u $USERNAME pip install pwn > /dev/null 2>&1
check "Error instalando pwn ($USERNAME)"

# stegcracker
info "Instalando stegcracker"
pip3 install stegcracker > /dev/null 2>&1
check "Error instalando stegcracker (root)"
sudo -u $USERNAME pip3 install stegcracker > /dev/null 2>&1
check "Error instalando stegcracker ($USERNAME)"


##################################################
# BSPWM / SXHKD                                  #
##################################################

section "bspwm / sxhkd"

# Instalación
info "Instalando bspwm y sxhkd"
apt install -y bspwm > /dev/null 2>/dev/null
check "Error en la instalación de bspwm"

# Configuración
info "Copiando archivos de configuración"
mkdir -p $HOME_PATH/.config/{bspwm,sxhkd} 2>/dev/null

cp -r $FILES_PATH/bspwm/* $HOME_PATH/.config/bspwm/ 2>/dev/null
check "No se encontró $FILES_PATH/bspwm/"
cp -r $FILES_PATH/sxhkd/* $HOME_PATH/.config/sxhkd/ 2>/dev/null
check "No se encontró $FILES_PATH/sxhkd/"

chmod u+x $HOME_PATH/.config/bspwm/bspwmrc 2>/dev/null
chmod u+x $HOME_PATH/.config/bspwm/scripts/* 2>/dev/null
echo "exec bspwm" > $HOME_PATH/.xinitrc
chown -R $USERNAME:$USERNAME $HOME_PATH/.xinitrc $HOME_PATH/.config/{bspwm,sxhkd} 2>/dev/null


##################################################
# COMPTON                                        #
##################################################

section "compton"

info "Instalando compton"
apt install -y compton > /dev/null 2>&1
check "Fallo en la instalación de compton"
info "Copiando configuración de compton"
mkdir -p $HOME_PATH/.config/compton 2>/dev/null
if [ "$IS_VM" == 1 ]; then
	cp $FILES_PATH/compton/compton_vm.conf $HOME_PATH/.config/compton/compton.conf 2>/dev/null
	check "No se encontró $FILES_PATH/compton/compton_vm.conf"
else
	cp $FILES_PATH/compton/compton.conf $HOME_PATH/.config/compton/compton.conf 2>/dev/null
	check "No se encontró $FILES_PATH/compton/compton.conf"
fi
chown -R $USERNAME:$USERNAME $HOME_PATH/.config/compton 2>/dev/null


##################################################
# POLYBAR                                        #
##################################################

section "polybar"

info "Instalando dependencias de Polybar"
apt install -y build-essential git cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev > /dev/null 2>&1
check "Error instalando dependencias de Polybar"
info "Instalando dependencias opcionales de Polybar"
apt install -y libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev i3-wm libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev > /dev/null 2>&1
check "Error instalando dependencias opcionales de Polybar"

info "Descargando el último release de Polybar"
polybar_url=$(curl --silent 'https://github.com/polybar/polybar/releases' | grep 'https://.*/releases/download/' | cut -d '"' -f 2 | head -n 1)
wget "$polybar_url" -O /tmp/polybar.tar > /dev/null 2>&1
check "No se encontró el último release de Polybar"

info "Building Polybar"
tar -C /opt -xvf /tmp/polybar.tar > /dev/null 2>&1
check "No se pudo hacer build de Polybar"

info "Compilando Polybar"
cd /opt/polybar 2>/dev/null
mkdir build 2>/dev/null
cd build 2>/dev/null
cmake .. > /dev/null 2>&1
make -j$(nproc) > /dev/null 2>&1
check "Hubo un error compilando Polybar"
info "Instalando Polybar"
make install > /dev/null 2>&1
check "Error instalando polybar"

info "Copiando archivos de personalización de Polybar"
mkdir $HOME_PATH/.config/polybar 2>/dev/null
cp -r $FILES_PATH/polybar/* $HOME_PATH/.config/polybar 2>/dev/null
check "No se encontró $FILES_PATH/polybar/"
chown -R $USERNAME:$USERNAME $HOME_PATH/.config/polybar 2>/dev/null
chmod u+x $HOME_PATH/.config/polybar/launch.sh
chmod u+x $HOME_PATH/.config/polybar/scripts/*
check "Error dando permisos de ejecución a los scripts de Polybar"


##################################################
# AJUSTES DE LA TERMINAL                         #
##################################################

section "Ajustes de la terminal"

info "Instalando zsh"
apt install -y zsh > /dev/null 2>&1
check "Error installando zsh"
info "Estableciendo zsh como shell predeterminada"
usermod --shell /usr/bin/zsh root > /dev/null 2>&1
usermod --shell /usr/bin/zsh $USERNAME > /dev/null 2>&1

info "Instalando powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME_PATH/powerlevel10k > /dev/null 2>&1
check "Error en la clonación del repo de powerlevel10k"
cp -r $HOME_PATH/powerlevel10k /root/ 2>/dev/null
cp $FILES_PATH/p10k.zsh $HOME_PATH/.p10k.zsh 2>/dev/null
check "No se encontró $FILES_PATH/p10k.zsh"
ln -sf $HOME_PATH/.p10k.zsh /root/.p10k.zsh 2>/dev/null
cat $FILES_PATH/zshrc | sed "s/\/home\/[^\/]*\//\/home\/$USERNAME\//g" > $HOME_PATH/.zshrc
check "No se encontró $FILES_PATH/zshrc o hubo problemas reemplazando el PATH"
ln -sf $HOME_PATH/.zshrc /root/.zshrc
chown -R $USERNAME:$USERNAME $HOME_PATH/powerlevel10k $HOME_PATH/.p10k.zsh $HOME_PATH/.zshrc 2>/dev/null

info "Instalando lsd"
wget "https://github.com$(curl --silent https://github.com/Peltoche/lsd/releases | grep 'lsd_.*_amd64.deb' | awk -F '\"' '{print $2}' | head -n 1)" -O /tmp/lsd.deb > /dev/null 2>&1
check "Problema descargando el último release de lsd"
dpkg -i /tmp/lsd.deb > /dev/null 2>&1
check "Error en la instalación de lsd"

info "Instalando bat"
wget "https://github.com$(curl --silent https://github.com/sharkdp/bat/releases | grep 'bat_.*_amd64.deb' | awk -F '\"' '{print $2}' | head -n 1)" -O /tmp/bat.deb > /dev/null 2>&1
check "Problema descargando el último release de bat"
dpkg -i /tmp/bat.deb > /dev/null 2>&1
check "Error en la instalación de bat"

info "Instalando bat-extras"
git clone https://github.com/eth-p/bat-extras /opt/bat-extras > /dev/null 2>&1
check "Problema clonando el repo de bat-extras"
/opt/bat-extras/build.sh > /dev/null 2>&1
check "Error construyendo los binarios de bat-extras"
snap install ripgrep --classic > /dev/null 2>&1
check "Error instalando ripgrep - beautygrep dará problemas"
snap alias ripgrep.rg rg > /dev/null 2>&1

info "Instalando FZF"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf > /dev/null 2>&1
check "Error clonando el repositorio de FZF (root)"
echo -e "y\ny\nn" | ~/.fzf/install > /dev/null 2>&1
check "Error instalando FZF (root)"
git clone --depth 1 https://github.com/junegunn/fzf.git $HOME_PATH/.fzf > /dev/null 2>&1
check "Error clonando el repositorio de FZF ($USERNAME)"
chown -R $USERNAME:$USERNAME $HOME_PATH/.fzf 2>/dev/null
sudo -u $USERNAME $HOME_PATH/.fzf/install < <(echo -e "y\ny\nn") > /dev/null 2>&1
check "Error instalando FZF ($USERNAME)"

info "Añadiendo plugins a la zsh"
apt install -y zsh-autosuggestions zsh-syntax-highlighting > /dev/null 2>&1
check "Error instalando plugins a través de apt"
mkdir /usr/share/zsh-sudo 2>/dev/null
wget https://github.com/ohmyzsh/ohmyzsh/raw/master/plugins/sudo/sudo.plugin.zsh -O /usr/share/zsh-sudo/sudo.plugin.zsh > /dev/null 2>&1
check "Error descargando zsh-sudo"
mkdir /usr/share/zsh-vscode 2>/dev/null
wget https://github.com/ohmyzsh/ohmyzsh/raw/master/plugins/vscode/vscode.plugin.zsh -O /usr/share/zsh-vscode/vscode.plugin.zsh > /dev/null 2>&1
check "Error descargando zsh-vscode"

info "Descargando fuente (Hack Nerd Font)"
cd /usr/local/share/fonts/ 2>/dev/null
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip > /dev/null 2>&1
check "No se pudo descargar la fuente - https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip"
unzip Hack.zip > /dev/null 2>&1
rm Hack.zip 2>/dev/null

info "Configurando Gnome terminal"
sudo -u $USERNAME dconf write /org/mate/terminal/profiles/default/use-system-font 'false' 2>/dev/null
sudo -u $USERNAME dconf write /org/mate/terminal/profiles/default/font "'Hack Nerd Font Mono 12'" 2>/dev/null
sudo -u $USERNAME dconf write /org/mate/terminal/profiles/default/default-show-menubar 'false' 2>/dev/null
sudo -u $USERNAME dconf write /org/mate/terminal/profiles/default/scrollbar-position "'hidden'" 2>/dev/null
check  "Error configurando la Gnome terminal"


##################################################
# CONFIGURACIÓN DEL SISTEMA                      #
##################################################

section "Configuración del sistema"

# Hostname
info "Estableciendo hostname"
echo "$HOSTNAME" > /etc/hostname
sed -i "s/parrot/$HOSTNAME/g" /etc/hosts 2>/dev/null

# Oh my tmux!
info "Configurando Oh my Tmux! (root)"
cd
git clone https://github.com/gpakosz/.tmux.git > /dev/null 2>&1
check "Error clonando Oh my Tmux!"
ln -s -f .tmux/.tmux.conf 2>/dev/null
cp .tmux/.tmux.conf.local . 2>/dev/null
echo -e '# Uso de los combo Ctrl+flechas, Home y Fin\nset-option -g default-terminal "xterm-256color"\nset-window-option -g xterm-keys on\nbind -n Home send-key C-a\nbind -n End send-key C-e' >> .tmux.conf.local

info "Configurando Oh my Tmux! ($USERNAME)"
cd "$HOME_PATH"
git clone https://github.com/gpakosz/.tmux.git > /dev/null 2>&1
check "De nuevo, error clonando Oh my Tmux!"
chown -R $USERNAME:$USERNAME .tmux/ 2>/dev/null
ln -s -f .tmux/.tmux.conf 2>/dev/null
cp .tmux/.tmux.conf.local . 2>/dev/null
chown -R $USERNAME:$USERNAME .tmux.conf.local 2>/dev/null
echo -e '# Uso de los combo Ctrl+flechas, Home y Fin\nset-option -g default-terminal "xterm-256color"\nset-window-option -g xterm-keys on\nbind -n Home send-key C-a\nbind -n End send-key C-e' >> .tmux.conf.local

# Fondo de pantalla
info "Copiando fondo de pantalla a ~/Documents"
cp "$WALLPAPER_PATH" $HOME_PATH/Documents/wallpaper.png
check "No se pudo copiar el fondo de pantalla. Si el OS está en español, vas a tener que cambiar el bspwmrc"

# Rofi
info "Estableciendo tema personalizado de rofi"
mkdir $HOME_PATH/.config/rofi 2>/dev/null
echo "rofi.theme: /usr/share/rofi/themes/gruvbox-dark.rasi" > $HOME_PATH/.config/rofi/config
chown -R $USERNAME:$USERNAME $HOME_PATH/.config/rofi/ 2>/dev/null
check "Error estableciendo el tema de rofi"

# Nano
info "Estableciendo configuración de nano"
cp $FILES_PATH/nanorc $HOME_PATH/.nanorc 2>/dev/null
check "No se encontró $HOME_PATH/nanorc"
ln -sf $HOME_PATH/.nanorc /root/.nanorc 2>/dev/null
chown -R $USERNAME:$USERNAME $HOME_PATH/.nanorc 2>/dev/null

# Micro
info "Estableciendo configuración de micro"
mkdir -p {/root,$HOME_PATH}/.config/micro 2>/dev/null
cp -r $FILES_PATH/micro/* $HOME_PATH/.config/micro 2>/dev/null
check "Error copiando configuración de micro ($USERNAME)"
cp -r $FILES_PATH/micro/* /root/.config/micro 2>/dev/null
check "Error copiando configuración de micro (root)"

# Java 8 - seleccionamos esta versión por problemas de compatibilidad con BurpSuite
info "Seleccionando Java 8 como predeterminado"
option=$(echo | update-alternatives --config java | grep "java-8" | tr -d '*' | awk '{print $1}')
if [ ! $option ]; then
	error "No se encontró Java 8"
else
	echo "$option" | update-alternatives --config java > /dev/null 2>&1
	check "Error eligiendo Java 8 como predeterminado"
fi

# Msfconsole
info "Inicializando la DB de Metasploit"
service postgresql start 2>/dev/null && msfdb init > /dev/null 2>&1
check "No se pudo inicializar la DB de Metasploit"

# Ajustes de portátil
if [ "$IS_LAPTOP" == 1 ]; then
	info "PORTÁTIL: Quitando suspensión al bajar la tapa"
	cp $FILES_PATH/logind.conf /etc/systemd 2>/dev/null
	check "No se pudo restaurar /etc/systemd/logind.conf"

	info "PORTÁTIL: Habilitando tap-to-click"
	mkdir -p /etc/X11/xorg.conf.d 2>/dev/null
	cp $FILES_PATH/90-touchpad.conf /etc/X11/xorg.conf.d 2>/dev/null
	check "No se pudo restaurar /etc/X11/xorg.conf.d/90-touchpad.conf"
fi

# Descartar paquetes obsoletos
info "Eliminando paquetes sin usar (apt autoremove)"
apt autoremove -y > /dev/null 2>&1


# Finalización del script
section "INSTALACIÓN FINALIZADA"
tput cnorm
info "¡No olvides cambiar el WindowManager a bspwm!"
info "Debes reiniciar el ordenador para terminar la instalación"
yes_or_no "¿Quieres hacerlo ahora?"

section "Happy hacking =)" && sleep 2
if [ $input -eq 1 ]; then
	reboot
fi

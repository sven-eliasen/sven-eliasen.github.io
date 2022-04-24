#!/bin/bash

# Nom			: post-installation.Cheat.sh
# Description	: Création, configuration des users + installation de Cheat pour tout les users
# Auteurs		: Arthur DUPUIS, Joakim PETTERSEN, Léo PEROCHON
# Version		: 1.0

# S'arrète à la moindre erreur
set -e
set -x

# Vérifie qu'on est root
if [ $EUID -ne 0 ]
    then echo "Relancez le script en root"
    exit
fi

# Installation des dépendences
echo '##################################################'
echo '#      Instalation des dependances               #'
echo '##################################################'
apt install -y sudo git vim mlocate tree rsync mlocate figlet

echo "###########################################################"
echo "# 	Génération automatique des clés SSH du root         #"
echo "###########################################################"
mkdir ~/.ssh
chmod -v 700 ~/.ssh
ssh-keygen -t ed25519 -f  ~/.ssh/id_ed25519 -q -N ""
echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9rKzJBdQlBB8Iy9iqoYpyK8Y80vtn+nf6bcbQOR0yk6dsLmrN50qEE5NamR3gMEvqLqJjgxpUTHYTb5D4RSrgLJRJoLyDO+7E0xkac91YmbwDt6ewbNNqOeKkeGLxk5lXwYbvDqgRhApBZ+fWN5nY9q++iT/5a3R6dn4YV5DQ/2/SEp0tENlt0K0XeaqcjQADXPInTR2uDWslzZhto4b44U4hYQwMZuV6VmgyRhBNDUchp+jzQUSd3NXNFlFH+Tadj91ahotek/e78B3d0UK3l0YmVqQhP/OREgATMLS1gXOP8kKN2X/p1pZdhEfCfOBRmngqSf3Z0vpjOZb1sjXl user0" > ~/.ssh/authorized_keys

echo '##################################################'
echo '#         Configuration des aliases              #'
echo '##################################################'
cat > /etc/bash.bashrc << EOF
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'

# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

PS1='\n[\t] \u \h \w \n\$ '

alias rm='rm -iv --preserve-root'
alias chgrp='chgrp -v --preserve-root'
alias chmod='chmod -v --preserve-root'
alias chown='chown -v --preserve-root'
alias cp='cp -iv'
alias grep='grep --color'
alias halt='shutdown -h +1'
alias lsize='ls -lSr'
alias mv='mv -iv'
alias reboot='shutdown -r +1'
alias df='df -hT -x devtmpfs -x tmpfs'
alias notes='echo $(date +%A,\%d\ %B\ \(%F_%R\) ) "$*" >> ~/.notes'
alias plantu='netstat -plantu'
alias c='clear'

HISTSIZE=50000
EOF
echo "PS1='\n[\t] \u \h \w \n\$ '" >> /etc/skel/.bashrc
for user_home in /home/*;
do
	echo "PS1='\n[\t] \u \h \w \n\$ '" >> "$user_home/.bashrc"
done

echo '##################################################'
echo '#         Configuration de la bannière           #'
echo '##################################################'
echo 'NONE="\033[m"
WHITE="\033[1;37m"
GREEN="\033[1;32m"
RED="\033[0;32;31m"
YELLOW="\033[1;33m"
BLUE="\033[34m"
CYAN="\033[36m"
LIGHT_GREEN="\033[1;32m"
LIGHT_RED="\033[1;31m"
' > /etc/update-motd.d/colors
echo '#!/bin/sh
. /etc/update-motd.d/colors
printf "\n"$LIGHT_RED
figlet " "$(hostname -s)
printf $NONE
printf "\n"
' > /etc/update-motd.d/00-hostname
chmod 755 /etc/update-motd.d/00-hostname
echo '#!/bin/bash
#author art0v1r0s 2022 mars

. /etc/update-motd.d/colors

[ -r /etc/update-motd.d/lsb-release ] && . /etc/update-motd.d/lsb-release

if [ -z "$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
    # Fall back to using the very slow lsb_release utility
    DISTRIB_DESCRIPTION=$(lsb_release -s -d)
fi

re="(.*\()(.*)(\).*)"
if [[ $DISTRIB_DESCRIPTION =~ $re ]]; then
    DISTRIB_DESCRIPTION=$(printf "%s%s%s%s%s" "${BASH_REMATCH[1]}" "${YELLOW}" "${BASH_REMATCH[2]}" "${NONE}" "${BASH_REMATCH[3]}")
fi

echo -e "  "$DISTRIB_DESCRIPTION "(kernel "$(uname -r)")\n"

# Update the information for next time
printf "DISTRIB_DESCRIPTION=\"%s\"" "$(lsb_release -s -d)" > /etc/update-motd.d/lsb-release &
' > /etc/update-motd.d/10-banner
chmod 755 /etc/update-motd.d/10-banner
echo '#!/bin/bash
proc=`cat /proc/cpuinfo | grep -i "^model name" | awk -F": " "{print $2}"`
memfree=`cat /proc/meminfo | grep MemFree | awk {"print $2"}`
memtotal=`cat /proc/meminfo | grep MemTotal | awk {"print $2"}`
uptime=`uptime -p`
addrip=`hostname -I | cut -d " " -f1`
# Récupérer le loadavg
read one five fifteen rest < /proc/loadavg

# Affichage des variables
printf "  Processeur : $proc"
printf "\n"
printf "  Charge CPU : $one (1min) / $five (5min) / $fifteen (15min)"
printf "\n"
printf "  Adresse IP : $addrip"
printf "\n"
printf "  RAM : $(($memfree/1024))MB libres / $(($memtotal/1024))MB"
printf "\n"
printf "  Uptime : $uptime"
printf "\n"
printf "\n"
' > /etc/update-motd.d/20-syinfo
chmod 755 /etc/update-motd.d/20-syinfo
rm /etc/motd
ln -s /var/run/motd /etc/motd

echo '##################################################'
echo '#         Gestion des users & groupes            #'
echo '##################################################'
addgroup commun
useradd -m -s /bin/bash esgi
echo "esgi:Pa55w.rd" | chpasswd
usermod -aG sudo esgi
usermod -aG sudo davy
usermod -aG commun davy
usermod -aG commun esgi

# Installation de l'executable
echo '##################################################'
echo "#      Instalation de l'executable               #"
echo '##################################################'
wget https://github.com/cheat/cheat/releases/download/4.2.3/cheat-linux-amd64.gz
gunzip cheat-linux-amd64.gz
chmod +x cheat-linux-amd64
mv -v cheat-linux-amd64 /usr/local/bin/cheat

# Configuration du Cheat
echo '##################################################'
echo '#           Configuration de Cheat               #'
echo '##################################################'
mkdir -p /root/.config/cheat && cheat --init > /root/.config/cheat/conf.yml
git clone https://github.com/cheat/cheatsheets
mkdir -vp /root/.config/cheat/cheatsheets/community
mkdir -vp /root/.config/cheat/cheatsheets/personal
mv /root/cheatsheets/* /root/.config/cheat/cheatsheets/community

mkdir -vp /opt/COMMUN
mv -v /root/.config/cheat/ /opt/COMMUN/
chown -R :commun /opt/COMMUN/
chmod -R 770 /opt/COMMUN/
ln -s /opt/COMMUN/cheat /root/.config/cheat

for user_home in /home/*;
do
	mkdir -vp "$user_home/.config"
	ln -s /opt/COMMUN/cheat "$user_home/.config/cheat"
	IFS='/'
	read -ra ARR <<< $user_home
	usermod -g commun ${ARR[2]}
done

mkdir -vp /etc/skel/.config
ln -s /opt/COMMUN/cheat /etc/skel/.config/cheat

echo 'umask 007 -R /opt/COMMUN/' >> /etc/bash.bashrc

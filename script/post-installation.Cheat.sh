#!/bin/bash

# Nom			: post-installation.Cheat.sh
# Description		: Création, configuration des users + installation de Cheat pour tout les users
# Auteurs		: Arthur DUPUIS, Joakim PETTERSEN, Léo PEROCHON
# Version		: 1.0

# S'arrète à la moindre erreur
#set -e
#set -x

# Vérifie qu'on est root
if [ $EUID -ne 0 ]
    then echo "Relancez le script en root"
    exit
fi

# Installation des dépendences
echo '##################################################'
echo '#      Instalation des dependances               #'
echo '##################################################'
in-target apt install -y sudo git vim mlocate tree rsync mlocate figlet

echo "###########################################################"
echo "# 	Génération automatique des clés SSH du root         #"
echo "###########################################################"
mkdir /target/root/.ssh
chmod -v 700 /target/root/.ssh
ssh-keygen -t ed25519 -f  /target/root/.ssh/id_ed25519 -q -N ""
echo "PermitRootLogin prohibit-password" >> /target/etc/ssh/sshd_config
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9rKzJBdQlBB8Iy9iqoYpyK8Y80vtn+nf6bcbQOR0yk6dsLmrN50qEE5NamR3gMEvqLqJjgxpUTHYTb5D4RSrgLJRJoLyDO+7E0xkac91YmbwDt6ewbNNqOeKkeGLxk5lXwYbvDqgRhApBZ+fWN5nY9q++iT/5a3R6dn4YV5DQ/2/SEp0tENlt0K0XeaqcjQADXPInTR2uDWslzZhto4b44U4hYQwMZuV6VmgyRhBNDUchp+jzQUSd3NXNFlFH+Tadj91ahotek/e78B3d0UK3l0YmVqQhP/OREgATMLS1gXOP8kKN2X/p1pZdhEfCfOBRmngqSf3Z0vpjOZb1sjXl user0" > /target/root/.ssh/authorized_keys

echo '##################################################'
echo '#         Configuration des aliases              #'
echo '##################################################'
cat > /target/etc/bash.bashrc << EOF
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
echo "PS1='\n[\t] \u \h \w \n\$ '" >> /target/etc/skel/.bashrc
for user_home in /target/home/*;
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
' > /target/etc/update-motd.d/colors
echo '#!/bin/sh
. /etc/update-motd.d/colors
printf "\n"$LIGHT_RED
figlet " "$(hostname -s)
printf $NONE
printf "\n"
' > /target/etc/update-motd.d/00-hostname
chmod 755 /target/etc/update-motd.d/00-hostname
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
' > /target/etc/update-motd.d/10-banner
chmod 755 /target/etc/update-motd.d/10-banner
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
' > /target/etc/update-motd.d/20-syinfo
chmod 755 /target/etc/update-motd.d/20-syinfo
rm /target/etc/motd
ln -s /target/var/run/motd /target/etc/motd

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

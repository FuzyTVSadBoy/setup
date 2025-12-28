#!/data/data/com.termux/files/usr/bin/bash
s=/data/data/com.termux/files/usr; e=$s/etc/termux; l=$e/chosen_mirrors; m=$e/mirrors/all
source $s/bin/termux-setup-package-manager || exit
[ "$1" = "--help" ] || [ "$1" = "-help" ] && echo -e "Usage: termux-change-repo\nhttps://github.com/termux/termux-packages/wiki/Mirrors" && exit
command -v apt >/dev/null || exit
[ "$TERMUX_APP_PACKAGE_MANAGER" = "pacman" ] && { read -p "Only for apt. Continue? [y/N] " -n1 r; echo; [[ $r =~ ^[Nn]$ ]] && exit; }
mkdir -p $s/tmp; [ -L $l ] && unlink $l; ln -sf $m $l
TERMUX_APP_PACKAGE_MANAGER=apt pkg --check-mirror update
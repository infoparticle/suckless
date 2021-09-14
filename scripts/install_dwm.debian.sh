#!/bin/env bash

pushd . > /dev/null

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SRC_DIR=$SCRIPT_DIR/../src
[[ ! -d $SRC_DIR ]] && mkdir -p $SRC_DIR

install_alacritty_git() {
	apt install git -y
	apt install snapd -y
	snap install core
	snap install alacritty --classic
}

download_suckless_repo(){
	git clone https://git.suckless.org/$i $SRC_DIR/$i.git
	CP $SRC_DIR/$i.git/config.def.h $SRC_DIR/$i.git/config.h
	cd $SRC_DIR/$i.git
	git add  config.h
	git commit -a -m "adding config.h"
}

download_suckless_allrepos() {
	for i in dwm slock dmenu sent slstatus;do
		download_suckless_repo $i
	done
}

build_suckless_dwm(){
	apt install make gcc libx11-dev libxft-dev libxinerama-dev xorg -y
	cd $SCRIPT_DIR/../src/dwm.git
	cp $SCRIPT_DIR/patches/base-patch-dwm.diff base-patch-dwm.diff
	git apply base-patch-dwm.diff
	make clean install
}

build_suckless_dmenu(){
	cd $SCRIPT_DIR/../src/dmenu.git
	make clean install
}

build_suckless_repo(){
	cd $SCRIPT_DIR/../src/$i.git
	make clean install

}

update_lightdm(){
DWM_DESKTOP=/usr/share/xsessions/dwm.desktop
cat >$DWM_DESKTOP <<EOM
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic window manager
Exec=startdwm
Icon=dwm
Type=XSession
EOM

DWM_START=/usr/local/bin/startdwm
cat >$DWM_START <<EOM
#!/bin/sh
/usr/local/bin/dwm
EOM

chmod +x /usr/local/bin/startdwm

echo "Updated $DWM_DESKTOP" 
echo "$(ls -l $DWM_DESKTOP)": 
cat $DWM_DESKTOP |sed 's/^/    /g'
echo
echo "Updated $DWM_START"
echo "$(ls -l $DWM_START)": 
cat $DWM_START |sed 's/^/    /g'

}

main() {
	install_alacritty_git
	download_suckless_allrepos
	build_suckless_repo dwm
	build_suckless_repo dmenu
	build_suckless_repo slstatus
	update_lightdm
}

download_suckless_repo slstatus
build_suckless_repo slstatus
popd > /dev/null

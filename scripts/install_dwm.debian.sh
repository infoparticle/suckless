#!/bin/env bash
pushd . > /dev/null

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SRC_DIR=$(dirname $SCRIPT_DIR)/src
BUILD_ROOT=/tmp/boot-strap
echo "BUILD_ROOT = $BUILD_ROOT"

[[ ! -d $BUILD_ROOT ]] && mkdir -p $BUILD_ROOT

install_alacritty_git() {
	apt install git -y
	apt install snapd -y
	snap install core
	snap install alacritty --classic
}

download_suckless_repo(){
	echo git clone https://git.suckless.org/$1 $BUILD_ROOT/$1.git
	cp $BUILD_ROOT/$1.git/config.def.h $BUILD_ROOT/$1.git/config.h
	cd $BUILD_ROOT/$1.git
	git add  config.h
	git commit -a -m "adding config.h"
}

download_suckless_allrepos() {
	for i in dwm slock dmenu sent slstatus;do
		download_suckless_repo $i
	done
}

build_suckless_custom_dwm(){
	apt install make gcc libx11-dev libxft-dev libxinerama-dev xorg -y
	cp $SCRIPT_DIR/patches/base-patch-dwm.diff $BUILD_ROOT/dwm.git/base-patch-dwm.diff
	cd $BUILD_ROOT/dwm.git
	git apply base-patch-dwm.diff
	make clean install >build.log 2>&1
}

build_suckless_dmenu(){
	cd $BUILD_ROOT/dmenu.git
	make clean install >build.log 2>&1
}

build_suckless_repo(){
	cd $BUILD_ROOT/$1.git
	make clean install >build.log 2>&1

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
xsetroot -solid '#334455'
while true; do
	/usr/local/bin/dwm
done
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

_emit_slsstatus_config_header(){
cat <<EOM
const unsigned int interval = 1000;
static const char unknown_str[] = "n/a";
#define MAXLEN 2048
EOM
if [[ -d /sys/class/power_supply/BAT0 ]]; then
	cat <<EOM
static const struct arg args[] = {
	{ battery_perc, " %s ",           "BAT0" },
	{ datetime, " %s ",           "%a %b %d %I:%M %p" },
};
EOM
return
fi
if [[ -d /sys/class/power_supply/BAT1 ]]; then
	cat <<EOM
static const struct arg args[] = {
	{ battery_perc, " %s ",           "BAT1" },
	{ datetime, " %s ",           "%a %b %d %I:%M %p" },
};
EOM
return
fi



cat <<EOM
static const struct arg args[] = {
	{ datetime, " %s ",           "%a %b %d %I:%M %p" },
};
EOM

}

build_suckless_custom_slstatus(){
	cd $BUILD_ROOT/slstatus.git
	_emit_slsstatus_config_header > $BUILD_ROOT/slstatus.git/config.h
	make install
}

main() {
	install_alacritty_git
	download_suckless_allrepos

	build_suckless_custom_dwm
	build_suckless_repo dmenu

	download_suckless_repo slstatus
	build_suckless_custom_slstatus

	update_lightdm
}

main
popd > /dev/null

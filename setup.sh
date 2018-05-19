#!/bin/bash

home="$(eval echo ~$user)"

# check, if sudo is used
check_sudo ()
{
    if [[ "$(id -u)" -eq 0 ]]; then
        echo "Script must NOT be run under sudo."
        exit 1
    fi
}

unknown_os ()
{
  echo "Unfortunately, your operating system distribution, version, kernel or drivers are not supported by this script."
  exit 1
}

detect_os ()
{
  if [[ ( -z "${os}" ) && ( -z "${dist}" ) ]]; then
    if [ `which lsb_release 2>/dev/null` ]; then
      dist=`lsb_release -c | cut -f2`
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`
    else
      unknown_os
    fi
  fi

  if [ -z "$dist" ]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="${os// /}"
  dist="${dist// /}"

  echo "Detected operating system as $os/$dist"
}

check_os () {
    detect_os
    
    if [[ "${os}" != "debian" || "${dist}" != "stretch" ]]; then
        unknown_os
    fi
}

check_kernel () {
    if [[ ( -z "${kernel}" ) ]]; then
        kernel=`uname -r`
        if [[ -z "$dist" ]]; then
            unknown_os
        fi
        
        
        
        if [[ "${kernel}" != "4.4.119-rockchip" ]]; then
            echo "Detected kernel version as $kernel"
            unknown_os
        fi
        
        echo "Detected kernel version as $kernel"
    fi
}

check_drivers () {
    if [[ ( -z "${drivers}" ) ]]; then
        drivers=`cat /sys/module/midgard_kbase/version`
        if [[ -z "$drivers" ]]; then
            unknown_os
        fi
        
        
        
        if [[ "${drivers}" != "r14p0-01rel0 (UK version 10.6)" ]]; then
            echo "Detected drivers version as $drivers"
            unknown_os
        fi
        
        echo "Detected drivers version as $drivers"
    fi
}

install () {
    read -p "Do you want to continue, this will update your system and install the required packages and drivers? (Y/N)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo ""
        echo "#######################"
        echo "##  Updating system  ##"
        echo "#######################"
        echo ""
        sudo apt update
        sudo apt upgrade -y
        
        echo ""
        echo "############################################"
        echo "##  Installing various required packaged  ##"
        echo "############################################"
        echo ""
        sudo apt install -y libtool cmake autoconf automake libxml2-dev libusb-1.0-0-dev libavcodec-dev libavformat-dev libavdevice-dev mpv
        
        echo ""
        echo "#################################"
        echo "##  Installing kernel headers  ##"
        echo "#################################"
        echo ""
        sudo apt install -y linux-headers-rockchip
        
        echo ""
        echo "##############################################"
        echo "##  Installing requirements for GPU driver  ##"
        echo "##############################################"
        echo ""
        sudo apt install -y libdrm2 libx11-6 libx11-data libx11-xcb1 libxau6 libxcb-dri2-0 libxcb1 libxdmcp6
        echo ""
        echo "#######################################"
        echo "##  Installing GPU userspace driver  ##"
        echo "#######################################"
        echo ""
        wget https://github.com/rockchip-linux/rk-rootfs-build/raw/master/packages/armhf/libmali/libmali-rk-midgard-t76x-r14p0-r0p0_1.6-1_armhf.deb
        sudo dpkg -i libmali-rk-midgard-t76x-r14p0-r0p0_1.6-1_armhf.deb
        wget https://github.com/rockchip-linux/rk-rootfs-build/raw/master/packages/armhf/libmali/libmali-rk-dev_1.6-1_armhf.deb
        sudo dpkg -i libmali-rk-dev_1.6-1_armhf.deb
        
        rm *.deb
        
        echo ""
        echo "################################################################"
        echo "##  Installing libDRM with experimental rockchip API support  ##"
        echo "################################################################"
        echo ""
        sudo apt install -y xutils-dev
        git clone --branch rockchip-2.4.74 https://github.com/rockchip-linux/libdrm-rockchip.git
        cd libdrm-rockchip
        ./autogen.sh --disable-intel --enable-rockchip-experimental-api --disable-freedreno --disable-tegra --disable-vmwgfx --disable-vc4 --disable-radeon --disable-amdgpu --disable-nouveau
        make -j4 && sudo make install
        cd ~
        rm -rf libdrm-rockchip
        
        echo ""
        echo "##########################"
        echo "##  Installing libmali  ##"
        echo "##########################"
        echo ""
        git clone --branch rockchip https://github.com/rockchip-linux/libmali.git
        cd libmali
        cmake CMakeLists.txt
        make -j4 -C ~/libmali && sudo make install
        cd ~
        rm -rf libmali
        
        echo ""
        echo "######################"
        echo "##  Installing MPP  ##"
        echo "######################"
        echo ""
        git clone https://github.com/rockchip-linux/mpp.git
        cd mpp
        cmake -src-dir ~/mpp -DRKPLATFORM=ON -DHAVE_DRM=ON
        make -j4 && sudo make install
        cd ~
        rm -rf mpp
        
        echo ""
        echo "##########################"
        echo "##  Installing Wayland  ##"
        echo "##########################"
        echo ""
        sudo apt install libffi-dev libexpat1-dev
        git clone https://github.com/wayland-project/wayland.git
        cd wayland
        ./autogen.sh --disable-documentation
        make -j4 && sudo make install
        cd ~
        rm -rf wayland
        
        echo ""
        echo "########################"
        echo "##  Cloning RetroPie  ##"
        echo "########################"
        echo ""
        git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
        
        echo ""
        echo "############################"
        echo "##  Installing bluetooth  ##"
        echo "############################"
        echo ""
        sudo apt install -y bluetooth
        sudo sed -i "/ExecStart=/i\ExecStartPre=/usr/sbin/rfkill unblock all" /lib/systemd/system/tinker-bluetooth.service
        sudo sed -i "/ExecStart=/a\Restart=on-failure" /lib/systemd/system/tinker-bluetooth.service

        echo ""
        echo "###############################"
        echo "##  Launch bluetooth service ##"
        echo "###############################"
        echo ""
        sudo systemctl stop tinker-bluetooth-restart
        sudo systemctl disable tinker-bluetooth-restart
        sudo rm /lib/systemd/system/tinker-bluetooth-restart.service
        sudo systemctl daemon-reload
        sudo systemctl stop tinker-bluetooth
        sudo systemctl start tinker-bluetooth
        
        ###############################
        ## Add no password for user  ##
        ###############################

        sudo sed -i "/sudoers(5)/i\# User no password privilege" /etc/sudoers
        sudo echo "$USER" | sed -i "/# User no password privilege/a\\$USER  ALL=(ALL) NOPASSWD: ALL" /etc/sudoers

        echo ""
        echo "##############################"
        echo "##  Installation complete.  ##"
        echo "##############################"
        echo "" 
    fi
        echo ""
        echo "##############################"
        echo "##  Optionnal installation  ##"
        echo "##############################"
        echo ""
        read -p "Do you want install Xbox One S Wireless support? (Y/N)" -n 1 -r
        echo
            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                sudo sed -i "/nothing./a\echo 1 > /sys/module/bluetooth/parameters/disable_ertm &\n" /etc/rc.local
            else
                echo "Run 'sudo ~/RetroPie-Setup/retropie_setup.sh' and then reboot your system. Then you can install the packages from RetroPie-Setup."
    fi   
}

main ()
{
    check_sudo
    check_os
    check_kernel
    check_drivers
    install
}

main

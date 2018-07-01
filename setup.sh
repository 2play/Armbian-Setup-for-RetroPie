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
        
        if [[ "${kernel}" != "4.4.135-rockchip" ]]; then
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
        
        
        
        if [[ "${drivers}" != "r18p0-01rel0 (UK version 10.6)" ]]; then
            echo "Detected drivers version as $drivers"
            unknown_os
        fi
        
        echo "Detected drivers version as $drivers"
    fi
}

install_basis () {
    read -p "Do you want to continue, this will update your system and install the required packages and drivers? (Y/N)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "###############################"
        echo "## Add no password for user  ##"
        echo "###############################"
        echo ""
        sudo sed -i "/sudoers(5)/i\# User no password privilege" /etc/sudoers
        sudo echo "$USER" | sudo sed -i "/# User no password privilege/a\\$USER  ALL=(ALL) NOPASSWD: ALL\n" /etc/sudoers
        echo "User no password privilege added"
        echo ""
    
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
        sudo apt install -y libtool cmake autoconf automake libxml2-dev libusb-1.0-0-dev libavcodec-dev \
                            libavformat-dev libavdevice-dev libdrm-dev pkg-config mpv
        
        echo ""
        echo "#################################"
        echo "##  Installing kernel headers  ##"
        echo "#################################"
        echo ""
        wget https://github.com/MySora/linux-headers/raw/master/armbian/linux-headers-rockchip_5.50.deb
        sudo dpkg -i linux-headers-rockchip_5.50.deb
        rm *.deb
        
        echo ""
        echo "##############################################"
        echo "##  Installing requirements for GPU driver  ##"
        echo "##############################################"
        echo ""
        sudo apt install -y libdrm2 libx11-6 libx11-data libx11-xcb1 libxau6 libxcb-dri2-0 libxcb1 \
                            libxdmcp6 libgles1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev
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
        git clone --branch rockchip-header https://github.com/MySora/libmali.git
        cd libmali
        cmake CMakeLists.txt
        make -j4 -C ~/libmali && sudo make install
        cd ~
        rm -rf libmali
        git clone --branch rockchip https://github.com/MySora/libmali.git
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
        echo "####################################"
        echo "##  Basic installation complete.  ##"
        echo "####################################"
        echo "" 
    fi
}

install_optional () {
    read -p "Do you want to make optional installations, such as bluetooth, audio source, etc ...? (Y/N)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo ""
        echo "##############################"
        echo "##  Optionnal installation  ##"
        echo "##############################"
        echo ""
        read -p "Do you want installed bluetooth? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
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
                
            echo ""
            echo "##  Bluetooth installed ##"
            echo ""
        fi        
            
        read -p "Do you want audio by HDMI? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "####################"
            echo "##  Audio source  ##"
            echo "####################"
            echo ""
            sudo sed -i "/defaults.pcm.card 0/c\defaults.pcm.card 1" /usr/share/alsa/alsa.conf
                    
            echo ""
            echo "##  Audio source on HDMI  ##"
        fi
                
        read -p "Do you want install Xbox One S Wireless support? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "#####################################"
            echo "##  Installing controller support  ##"
            echo "#####################################"
            echo ""
            sudo sed -i "/nothing./a\echo 1 > /sys/module/bluetooth/parameters/disable_ertm &\n" /etc/rc.local
                   
            echo ""
            echo "##  Xbox One S support installed  ##"
            echo ""
        fi
                    
        read -p "Do you want install Background Music? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "#####################################"
            echo "##  Install Background Music  ##"
            echo "#####################################"
            echo ""
            mkdir -p $HOME/RetroPie/roms/musics
            sudo mkdir -p /opt/retropie/config/all
            sudo wget https://github.com/JyuHo/Armbian-Setup-for-RetroPie/blob/master/autostart.sh -O /opt/retropie/config/all/autostart.sh
            sudo wget https://github.com/JyuHo/Armbian-Setup-for-RetroPie/blob/master/runcommand-onend.sh -O /opt/retropie/config/all/runcommand-onend.sh
            sudo wget https://github.com/JyuHo/Armbian-Setup-for-RetroPie/blob/master/runcommand-onstart.sh -O /opt/retropie/config/all/runcommand-onstart.sh
                        
            echo ""
            echo "##  Background Music ready  ##"
            echo "## You can drop your music files into ~/RetroPie/roms/musics"
            echo ""
        fi
                    
        read -p "Do you want install OMXPLAYER for splachscreen? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "#####################################"
            echo "##  Install OMXPLAYER  ##"
            echo "#####################################"
            echo ""
            wget http://ftp.de.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.2l-1~bpo8+1_armhf.deb
            sudo dpkg -i libssl1.0.0_1.0.2l-1~bpo8+1_armhf.deb
            sudo apt install -y libssh-4 fonts-freefont-ttf
            wget http://omxplayer.sconde.net/builds/omxplayer_0.3.7~git20170130~62fb580_armhf.deb
            sudo dpkg -i omxplayer_0.3.7~git20170130~62fb580_armhf.deb
            rm *.deb
                            
            echo ""
            echo "##  OMXPLAYER installed  ##"
            echo ""
        fi
                        
        echo ""
        echo "##############################"
        echo "##  Installation completed  ##"
        echo "##############################"
        echo ""
        echo "Run 'sudo ~/RetroPie-Setup/retropie_setup.sh' and then reboot your system. Then you can install the packages from RetroPie-Setup."
fi
}

main ()
{
    check_sudo
    check_os
    check_kernel
    check_drivers
    install_basis
    install_optional
}

main

# Armbian-Setup-for-RetroPie revamped by 2play!
setup2play.sh is an updated bash script for installing RetroPie on the Asus Tinkerboard.

All other files are the changes MySora did to make for (BGM) background music or other extras.

This is an updated/revamped version for Armbian 5.60 kernel 4.4.152 (will be upgraded to 4.4.156) with a working libmali version r14p0.

# How to use...

- Get a clean Armbian OS Debian Stretch image from Armbian downloads. Select Asus/Tinkerboard and scroll at the bottom. Dont use the mainline... 
- Burn & Boot it.
- Create pi user at first boot
- reboot
- ssh to it
- wget https://github.com/2play/Armbian-Setup-for-RetroPie/raw/master/setup2play.sh 
- `sudo chmod 777 setup2play.sh`
- Edit setup script versions as needed bss kernel and rk chip.
for headers (NO NEED if you use latest stable 4.4.152 > will be upgraded to 4.4.156 stable)
- run ./setup2Play.sh

From optional dont run HDMI Audio at this time.
	You can change if needed with below command and reverse it

Enable
 sudo sed -i "/defaults.pcm.card 0/c\defaults.pcm.card 1" /usr/share/alsa/alsa.conf

Disable/Reverse
 sudo sed -i "/defaults.pcm.card 1/c\defaults.pcm.card 0" /usr/share/alsa/alsa.conf

- Reboot System 
- Run 'sudo ~/RetroPie-Setup/retropie_setup.sh'
- Install samba shares (Click again top option to enable after samba install)
- Copy your favorite splashscreen mp4 file in the splashcreen samba directory.
- Copy your music to /roms/music/ directory for use by the BGM script.
- Install basic package or core packages if you want to test(From Source) 
wait .............
- Intall in driver the xpad driver
- Install any of the rest packs in optional/experimental
- Go to configuration/tools -> boot options -> And set emulationstation to start at boot

REBOOT! DONE!

You will be prompted to setup a controller..

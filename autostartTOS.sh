mpv /home/linaro/RetroPie/splashscreens/splash.mp4
clear
while pgrep omxplayer >/dev/null; do sleep 1; done
mpv --no-video /home/linaro/RetroPie/roms/music/*.mp3 >/dev/null 2>&1 &
emulationstation --no-splash #auto

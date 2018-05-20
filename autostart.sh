REGEX_VIDEO="\.avi\|\.mov\|\.mp4\|\.mkv\|\.3gp\|\.mpg\|\.mp3\|\.wav\|\.m4a\|\.a$
REGEX_AUDIO="\.mp3\|\.wav\|\.m4a\|\.aac\|\.ogg\|\.flac"

local rv="$REGEX_VIDEO"
local ra="$REGEX_AUDIO"

while pgrep omxplayer >/dev/null; do sleep 1; done
mpv /home/$USER/RetroPie/splashscreens/*"$rv"
(sleep 1; mpv --no-video /home/$USER/RetroPie/roms/music/*"$ra" >/dev/null 2>&1$
emulationstation #auto

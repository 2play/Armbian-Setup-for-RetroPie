REGEX_AUDIO="\.mp3\|\.wav\|\.m4a\|\.aac\|\.ogg\|\.flac"

local ra="$REGEX_AUDIO"

(sleep 1; mpv --no-video /home/$USER/RetroPie/roms/music/*"$ra" >/dev/null 2>&1$
emulationstation #auto

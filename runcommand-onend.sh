REGEX_AUDIO="\.mp3\|\.wav\|\.m4a\|\.aac\|\.ogg\|\.flac"

ra="$REGEX_AUDIO"

mpv --no-video --loop --shuffle /home/$USER/RetroPie/roms/musics/*"$ra" >/dev/null 2>&1 &

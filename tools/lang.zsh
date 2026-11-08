# Language of the scripts' messages: French if it is the system's primary
# language, English otherwise. Usage: say "message en français" "English message"
if [[ "$(defaults read -g AppleLanguages 2>/dev/null | sed -n 2p)" == *\"fr* ]]; then
    KBD_FR=1
else
    KBD_FR=0
fi
say() { if (( KBD_FR )); then print -r -- "$1"; else print -r -- "$2"; fi }

function main() {
    VOLUME=$(pamixer --get-volume-human)
    IS_MUTED=$(pamixer --get-mute)

    action=$1
    if [ "${action}" == "up" ]; then
        pamixer --increase 5
    elif [ "${action}" == "down" ]; then
        pamixer --decrease 5
    elif [ "${action}" == "mute" ]; then
        pamixer --toggle-mute
    else
        if [ "${IS_MUTED}" == true ]; then
            echo "󰟎"
        else
            echo "󰋋  ${VOLUME}%"
        fi
    fi
}

main $@

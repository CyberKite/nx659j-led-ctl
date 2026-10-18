#!/system/bin/env sh
set -eu
LED=/sys/class/leds/aw22xxx_led
[ -d "${LED}" ] || exit 1

led_color(){
    i=0
    while [ "${i}" -lt 9 ]; do
	printf "%x %s\n" "${i}" "${1}" > "${LED}/rgb"
	i=$((i + 1))
    done

    echo 255 > "${LED}/brightness"
    case "${2}" in
	flash) echo 81 > "${LED}/effect";;
	music) echo 50 > "${LED}/effect";;
	solid|*) echo 61 > "${LED}/effect";;
    esac

    sleep 0.2

    echo 2 > "${LED}/cfg"
}

led_off(){
    echo 0 > "${LED}/brightness"
}

case "${1}" in
    off) led_off;;
    *) led_color "${1}" "${2:-solid}";;
esac

#!/system/bin/env sh

set -eu
MODPATH="${0%/*}"

set +eu
# shellcheck source=SCRIPTDIR/config.sh.default
. "${MODPATH}/config.sh"
set -eu

# shellcheck source=SCRIPTDIR/color-utils.sh
. "${MODPATH}/color-utils.sh"

log(){
    command log -t nx659j-led "$*"
}

ledctl(){
    command "${MODPATH}/ledctl.sh" "${@}" || { log "led write failed: $*"; true; }
}

secex(){
    section="$1"
    key="$2"

    dumpsys display 2>/dev/null | awk -v section="${section}" -v key="${key}" '
        $0 ~ "^[[:space:]]*" section "[[:space:]]*$" {
            in_section=1
            next
        }
        /^[[:space:]]*$/ {
            in_section=0
        }
        in_section && $0 ~ key {
            sub(/.*=/, "")
            print
            exit
        }
    '
}

get_screen_state(){ secex 'BrightnessTracker state:' 'mIsDisplayActive'; }
get_charge_state(){ dumpsys battery get status -f | tr -d '[:space:]'; }

daemon(){
    iteration=0
    next_check=0
    last=""
    cache_variables=''
    while true; do
	iteration=$((iteration + 1))
	scr_state=$(get_screen_state)
	case "${scr_state}" in
	    true) scr_state=1;;
	    false) scr_state=0;;
	    *) ;;
	esac
	bat_state=$(get_charge_state)
	state="${scr_state}:${bat_state}"

	# this is a compromise between material accents changing occasionally
	# (eg. on multiuser devices) and not needlessly polling.
	# Gloriously inefficient.
	if [ "${iteration}" -ge "${next_check}" ]; then
	    wipe_color_cache
	    next_check=$((iteration + COLOR_INTERVAL))
	fi

	# I am aware this blocks color when the state doesn't flag.
	# This is mostly fine, though, since you often don't want to
	# change color in flight for no reason anyway
	if [ "${state}" = "${last}" ]; then
	    sleep "${CHECK_INTERVAL}"
	    continue
	fi

	log "state: ${state}"

	# 1: Unknown
	# 2: Charging
	# 3: Discharging
	# 4: Not Charging
	# 5: Full

	# I don't really care, resolve_colorpipe is fairly simple,
	# and we need to do this at RT
	# shellcheck disable=SC2312
	case "${state}" in
	    *:2)
		resolve_colorpipe "${CHARGE_COLOR}"
		ledctl "${color}" "${CHARGE_ANIM}"
		;;
	    *:5)
		resolve_colorpipe "${FULL_COLOR}"
		ledctl "${color}" "${FULL_ANIM}"
		;;
	    1:*)
		resolve_colorpipe "${SCREEN_ON_COLOR}"
		ledctl "${color}" "${SCREEN_ON_ANIM}"
		;;
	    0:*)
		resolve_colorpipe "${SCREEN_OFF_COLOR}"
		ledctl "${color}" "${SCREEN_OFF_ANIM}"
		;;
	    *)
		# this condition occurs at boot
		# because stuff hasn't really initialised yet.
		# White flashing should be fine.
		resolve_colorpipe "${FALLBACK_COLOR}"
		ledctl "${color}" "${FALLBACK_ANIM}"
		;;
	esac

	last="${state}"

	sleep "${CHECK_INTERVAL}"
    done
}

# BEFORE ANYONE ASKS, the second arg is OLD_VALUE
resetprop -w sys.boot_completed 0

# SIIIIIIIIGHHHHH
PIDFILE=/dev/nx659j-led-service.pid

cleanup() {
    if [ -f "${PIDFILE}" ]; then
	file_pid=$(cat "${PIDFILE}")
	[ "${file_pid}" = "$$" ] && rm -f "${PIDFILE}"
    fi
}

# I'm intentionally using echo here because this only makes sense
# when you're restarting the daemon by hand
file_pid=$(cat "${PIDFILE}" 2>/dev/null) || file_pid=''
case "${file_pid}" in
    ''|*[!0-9]*)
        file_pid=''
        ;;
    *)
esac
if [ -n "${file_pid}" ]; then
    echo "existing instance marker"
    if kill -0 "${file_pid}"; then
	echo "killing..."
	kill -15 "${file_pid}" || true
    else
	echo "it died already."
    fi
    t=10
    while kill -0 "${file_pid}" 2>/dev/null; do
	t=$((t - 1))
	if [ "${t}" -lt 0 ]; then
	    echo "it's not dying, trying -9."
	    kill -9 "${file_pid}" 2>/dev/null || true
	    sleep 2
	    break
	fi
	sleep 1
    done
fi

echo "enabling MultiMedia1 -> LED route..."
if ! "${MODPATH}/tinymix" -D 0 set \
    "RX_CDC_DMA_RX_0 Audio Mixer MultiMedia1" 1 1; then
    log "WARNING: failed to enable LED audio route"
fi

echo "starting daemon..."
printf '%s' "$$" > "${PIDFILE}"
trap cleanup EXIT
trap 'exit 0' TERM INT

daemon

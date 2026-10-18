#!/system/bin/env sh

PIDFILE=/dev/nx659j-led-service.pid
MODPATH="${0%/*}"

if [ -f "${PIDFILE}" ]; then
    pid=$(cat "${PIDFILE}")

    case "${pid}" in
        ''|*[!0-9]*) ;;
        *)
            kill "${pid}" 2>/dev/null || true
            ;;
    esac
fi

"${MODPATH}/ledctl.sh" off 2>/dev/null || true
rm -f "${PIDFILE}"

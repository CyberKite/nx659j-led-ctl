#!/system/bin/env sh

set -eu
MODPATH="${0%/*}"

BOOT_COLOR=ff0000
BOOT_ANIM=solid

set +eu
# shellcheck source=SCRIPTDIR/config.sh.default
. "${MODPATH}/config.sh"
set -eu

"${MODPATH}/ledctl.sh" "${BOOT_COLOR}" "${BOOT_ANIM}"

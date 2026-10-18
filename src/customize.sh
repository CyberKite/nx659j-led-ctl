#SOURCEABLE

[ -z "${MODPATH}" ] && return 1

chmod 755 \
    "${MODPATH}/service.sh" \
    "${MODPATH}/ledctl.sh" \
    "${MODPATH}/tinymix"
touch "${MODPATH}/skip_mount"

# shellcheck source=config.sh.default
if ! [ -f "${MODPATH}/config.sh" ]; then
    cp "${MODPATH}/config.sh.default" "${MODPATH}/config.sh"
fi

device=$(getprop ro.product.device)
build_flavour=$(getprop ro.build.flavor)

case "${device}" in
    NX659J)
        ;;
    *)
        ui_print "WARNING: This module was designed for NX659J devices."
        ui_print "Detected device: ${device}"
        ;;
esac

case "${build_flavour}" in
    lineage_nx659j-*) ;;
    *)
	ui_print "WARNING: This module was designed for LineageOS on NX659J"
	ui_print "(RedMagic 5G/S) -- Detected build flavour: ${build_flavour}"
	;;
esac

ui_print 'setting an example color...'
"${MODPATH}/ledctl.sh" 'ff0000' flash && e=0 || e=$?
if [ "${e}" -gt 0 ]; then
    ui_print 'Welp, that failed. Starting off strong...'
fi

ui_print "requesting hotinstall..."
export MODULE_HOT_INSTALL_REQUEST=true
export MODULE_HOT_RUN_SCRIPT=hotinstall.sh

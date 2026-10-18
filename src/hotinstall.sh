MODPATH="${0%/*}"
echo "starting service..."
nohup "${MODPATH}/service.sh" >/dev/null 2>&1 & pid=$!
sleep 3
kill -0 "${pid}" || ui_print "welp ig that failed."

#SOURCEABLE

log(){
    command log -t nx659j-led "$*"
}

is_hex(){
    case "${1}" in
    *[!0-9a-fA-F]*|'')
	return 1
	;;
    *)
	if [ "${#1}" -ne 6 ]; then
	    return 1
	fi
	return 0
	;;
    esac
}

store_color_cache(){
    cache_key="${1}"
    # trust me, shellcheck, it's used.
    # Just...in the evilest possible way.
    # shellcheck disable=SC2034
    cache_val=${2}
    eval "${cache_key}=\${cache_val}"
    cache_variables="${cache_variables}${cache_key} "
}

wipe_color_cache(){
    # it's like a forloop: we are intentionally splitting
    # shellcheck disable=2086
    unset ${cache_variables}
    cache_variables=''
}

get_material_color(){
    material_color=$(cmd overlay lookup --user 0 \
	android "${1:-android:color/system_accent1_500}" |
	sed -n 's/.*#..\(......\).*/\1/p')

    if ! is_hex "${material_color}"; then
	return 1
    fi

    echo "${material_color}"
}

color_saturate(){
    echo "${1}" | awk -v factor="${2:-2}" '
    function clamp(x) {
	if (x < 0) return 0
	if (x > 255) return 255
	return int(x)
    }
    function h2d(x,    i,n,c,v) {
	n=0
	for (i=1; i<=length(x); i++) {
	    c=tolower(substr(x,i,1))
	    if (c >= "0" && c <= "9")
		v=c
	    else
		v=index("abcdef",c)+9
	    n=n*16+v
	}
	return n
    }
    {
	c=$0

	r=h2d(substr(c,1,2))
	g=h2d(substr(c,3,2))
	b=h2d(substr(c,5,2))

	avg=(r+g+b)/3

	r=clamp(avg+(r-avg)*factor)
	g=clamp(avg+(g-avg)*factor)
	b=clamp(avg+(b-avg)*factor)

	printf "%02x%02x%02x\n", r,g,b
    }'
}

set_hsv_sat(){
    printf '%s\n' "${1}" | awk -v sat="${2:-1}" '
    function clamp(x) {
        if (x < 0) return 0
        if (x > 1) return 1
        return x
    }
    function h2d(x,    i,n,c,v) {
        n=0
        for (i=1; i<=length(x); i++) {
            c=tolower(substr(x,i,1))
            if (c >= "0" && c <= "9")
                v=c
            else
                v=index("abcdef",c)+9
            n=n*16+v
        }
        return n
    }
    function round(x) {
        return int(x+0.5)
    }
    {
        r=h2d(substr($0,1,2))
        g=h2d(substr($0,3,2))
        b=h2d(substr($0,5,2))

        max=r
        if (g > max) max=g
        if (b > max) max=b

        min=r
        if (g < min) min=g
        if (b < min) min=b

        delta=max-min
        sat=clamp(sat)

        # HSV value is max; preserve hue by scaling
        # each channels distance from max.
        if (delta == 0) {
            # Grayscale has no defined hue.
            r=max
            g=max
            b=max
        } else {
            scale=(max*sat)/delta

            r=max-(max-r)*scale
            g=max-(max-g)*scale
            b=max-(max-b)*scale
        }

        printf "%02x%02x%02x\n", round(r),round(g),round(b)
    }'
}

resolve_color(){
    color="${1}"

    case "${color}" in
	off)
	    return 0
	    ;;
	\$*)
	    colordef="${color#\$}"

	    case "${colordef}" in
		android:color/*) ;;
		system_*) colordef="android:color/${colordef}" ;;
		*)
		    log "invalid Material resource: '${colordef}'"
		    color=ff00ff
		    return 0
		    ;;
	    esac

	    # shellcheck disable=SC2310
	    color=$(get_material_color "${colordef}") && e=0 || e=$?
	    if [ "${e}" -ne 0 ]; then
		log "failed to resolve Material color: '${colordef}'"
		color=ff00ff
	    fi
	    ;;
	*)
	    color="${color#\#}"

	    if ! is_hex "${color}"; then
		log "invalid color spec: '${1}'"
		color=ff00ff
	    fi
	    ;;
    esac
}

resolve_colorpipe(){
    spec="${1}"

    cache_key=$(printf '%s' "${spec}" | sha256sum)
    cache_key=cached_color_${cache_key%% *}

    eval "cached=\"\${${cache_key}:-}\""
    if [ -n "${cached}" ]; then
	color="${cached}"
	return 0
    fi

    base="${spec%%"|"*}"
    resolve_color "${base}"

    # Don't transform 'off'
    if [ "${color}" = off ]; then
	store_color_cache "${cache_key}" "${color}"
	return 0
    fi

    case "${spec}" in
	*'|'*) post_ops="${spec#*"|"}" ;;
	*) post_ops='' ;;
    esac

    while [ -n "${post_ops}" ]; do
	op="${post_ops%%"|"*}"

	case "${post_ops}" in
	    *'|'*) post_ops="${post_ops#*"|"}" ;;
	    *) post_ops='' ;;
	esac

	case "${op}" in
	    boost:*)
		color=$(color_saturate "${color}" "${op#*:}")
		;;
	    hsvsat:*)
		color=$(set_hsv_sat "${color}" "${op#*:}")
		;;
	    *)
		log "invalid color operation: '${op}', skipping."
		;;
	esac
    done

    if [ "${color}" != off ] && ! is_hex "${color}"; then
	log "invalid pipeline output: '${spec}'"
	color=ff00ff
    fi

    store_color_cache "${cache_key}" "${color}"
}

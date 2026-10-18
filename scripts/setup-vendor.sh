#!/bin/sh
set -eu

vendor_tarball() (
    url=$1
    name=$2
    dest="vendor/${name}"
    ext="${url##*.}"

    if [ -d "${dest}" ]; then
	printf '%s already vendored\n' "${name}"
	return 0
    fi

    mkdir -p vendor
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    printf '%s -> %s\n' "${url}" "${dest}"

    case "${ext}" in
	gz)	tarflags="-z";;
	bz2)	tarflags="-j";;
	tar)	tarflags="";;
	*)	echo "${dest}: ${ext} unsupported"; exit 1;;
    esac

    tarball="${tmp}/archive.tar.${ext}"
    wget -qO "${tarball}" "${url}"
    mkdir "${tmp}/extracted"
    tar "${tarflags}" -xf "${tarball}" \
	-C "${tmp}/extracted" --strip-components=1

    mv "${tmp}/extracted" "${dest}"
)

vendor_tarball "https://github.com/tinyalsa/tinyalsa/archive/refs/tags/v2.0.0.tar.gz" tinyalsa
# we need this oddly specific build cause of UB. You are best off *not asking.*
vendor_tarball "https://downloads.sourceforge.net/project/sdcc/sdcc/4.4.0/sdcc-src-4.4.0.tar.bz2" sdcc

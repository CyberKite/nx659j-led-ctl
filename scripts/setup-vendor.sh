#!/bin/sh
set -eu

vendor_tarball() (
    url=$1
    name=$2
    dest="vendor/${name}"

    if [ -d "${dest}" ]; then
	printf '%s already vendored\n' "${name}"
	return 0
    fi

    mkdir -p vendor
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    printf '%s -> %s\n' "${url}" "${dest}"

    wget -qO "${tmp}/archive.tar.gz" "${url}"
    mkdir "${tmp}/extracted"
    tar -xzf "${tmp}/archive.tar.gz" \
	-C "${tmp}/extracted" --strip-components=1

    mv "${tmp}/extracted" "${dest}"
)

vendor_tarball \
    "https://github.com/tinyalsa/tinyalsa/archive/refs/tags/v2.0.0.tar.gz" \
    tinyalsa

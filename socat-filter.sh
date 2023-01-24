#!/bin/sh
catch_twfid() {
	TWFID="$(grep --line-buffered --max-count=1 '^[Cc]ookie:' | sed -E 's/.*TWFID=([^;]*)[; \r]/\1/')"
	echo "TWFID has been captured: $TWFID" >&2
	echo "Interrupt the connection!" >&2
	exec >&-
	exec 0<&-
	exit
}

read request
echo "$request" >&2
case "$request" in
	"GET /por/conf.csp"* ) catch_twfid;;
	"GET /por/rclist.csp"* ) catch_twfid;;
esac

replace_header() {
	sed -uE '/^('"$1"':.*\r|\r)$/{s/^'"$1"':.*/'"$2"'\r/;q}'
	cat -u
}
replace_host() {
	replace_header '[Hh]ost' "Host: $hostname"
}
disable_compress() {
	replace_header "[Aa]ceept-[Ee]ncoding" "Accept-Encoding: "
}
disable_keep_alive() {
	replace_header "[Cc]onnection" "Connection: close"
}

{ printf "%s\r\n" "$request" ; cat -u; } |
	replace_host |
	disable_compress |
	disable_keep_alive |
	socat - "ssl:$hostname:$port,verify=0" |
	disable_keep_alive

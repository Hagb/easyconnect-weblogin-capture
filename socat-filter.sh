#!/bin/sh
catch_twfid() {
	TWFID="$(sed -unE '/^[Cc]ookie:/{s/.*[^A-Za-z]TWFID=([^;]*)[; \r].*/\1/p; q}')"
	echo "TWFID has been captured: $TWFID" >&2
	echo "Interrupt the connection!" >&2
	exec >&-
	exec 0<&-
	exit
}
get_cert() {
	cat "$cert" | {
		sed -unE '/^.*BEGIN CERTIFICATE-*$/{p; q}'
		sed -uE '/^-*END CERTIFICATE-*$/q'
	}
}

new_content_length=""
new_body=""
read request
echo "$request" >&2
case "$request" in
	"GET /por/conf.csp"* ) catch_twfid;;
	"GET /por/rclist.csp"* ) catch_twfid;;
	"GET /com/server.crt"* )
		new_body="$(get_cert)"
		new_content_length=${#new_body};;
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
replace_body() {
	if [ -n "$new_content_length" ]; then
		sed -uE '/^\r$/q'
		printf "%s" "$new_body"
	else
		cat -u
	fi
}
replace_content_length() {
	if [ -n "$new_content_length" ]; then
		replace_header "[Cc]ontent-[Ll]ength" "Content-Length: $new_content_length"
	else
		cat -u
	fi
}

{ printf "%s\r\n" "$request" ; cat -u; } |
	replace_host |
	disable_compress |
	disable_keep_alive |
	socat - "ssl:$hostname:$port,verify=0" |
	disable_keep_alive | replace_content_length | replace_body

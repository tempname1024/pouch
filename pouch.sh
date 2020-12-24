#!/usr/bin/env bash

PROGRAM="${0##*/}"
AGENT="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:84.0) Gecko/20100101 Firefox/84.0"

cmd_usage() {
    cat >&2 <<-_EOF
Usage: $PROGRAM HTML_FILE_PATH

  HTML_FILE is a pocket-exported document containing the set of URLs to save

Dependencies:

  google-chrome 59+ (headless mode support)
  curl
_EOF
}

get_urls() {
    sed -n 's/.*href="\([^"]*\).*/\1/p' $1
}

url_to_filename() {
    echo "${1##*//}" |        # remove protocol (https://...)
        sed 's/\/$//' |       # remove trailing slash
        tr /. - |             # replace /. characters with -
        tr -cd '[[:alnum:]-]' # remove non-alphanumeric/"-" chars
}

save() {
    read url

    if [[ -f "$(url_to_filename $url).pdf" ]]; then
        return 0
    fi

    content_type=$(curl -s -I -A "$AGENT" "$url" | grep --ignore-case '^content-type:' | cut -d' ' -f2)
    pdfname=$(url_to_filename $url).pdf

    if [[ $content_type == *"application/pdf"* ]]; then
        echo [+] $url...
        curl -A "$AGENT" "$url" -o "$pdfname"
    else
        echo [+] $url...
        google-chrome --headless --disable-gpu --print-to-pdf="$pdfname" "$url"
    fi

}

if [[ $# -eq 1 && ( $1 == --help || $1 == -h || $1 == help ) ]]; then
    cmd_usage
elif [[ $# -eq 1 ]]; then
    get_urls $1 | while read line ; do save $line ; done
else
    cmd_usage
    exit 1
fi

exit 0

#!/bin/bash

steamcmd_dir="$HOME/steamcmd"

function fail()
{
        echo Error: "$@" >&2
        exit 1
}

function check_for_file()
{
        if [ ! -e "$1" ]; then
                fail "Missing file: $1"
        fi
}

cd "$steamcmd_dir" || fail "Missing $steamcmd_dir directory!"

check_for_file "steamcmd.sh"

download_item=(./steamcmd.sh)
download_item+=(+login anonymous)
download_item+=(+workshop_download_item 322330 2659976744 validate)
download_item+=(+workshop_download_item 322330 2823530744 validate)
download_item+=(+workshop_download_item 322330 378160973 validate)
download_item+=(+quit)

"${download_item[@]}" || fail "Failed to download workshop items!"
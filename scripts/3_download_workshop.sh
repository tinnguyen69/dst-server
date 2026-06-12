#!/bin/bash

steamcmd_dir="$HOME/steamcmd"
workshop_dir="$HOME/Steam/steamapps/workshop/content/322330"
mods_dir="$HOME/dontstarvetogether_dedicated_server/mods"

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

cp -r "$workshop_dir/2659976744" "$mods_dir/workshop-2659976744"
cp -r "$workshop_dir/2823530744" "$mods_dir/workshop-2823530744"
cp -r "$workshop_dir/378160973" "$mods_dir/workshop-378160973"
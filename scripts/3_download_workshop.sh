#!/bin/bash

steamcmd_dir="$HOME/steamcmd"
install_dir="$HOME/dontstarvetogether_dedicated_server"
workshop_dir="$HOME/Steam/steamapps/workshop/content/322330"

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
download_item+=(+workshop_download_item 322330 1185229307 validate)
download_item+=(+quit)

"${download_item[@]}" || fail "Failed to download workshop items!"

cp -r "$workshop_dir/2659976744" "$install_dir/mods/workshop-2659976744"
cp -r "$workshop_dir/2823530744" "$install_dir/mods/workshop-2823530744"
cp -r "$workshop_dir/378160973" "$install_dir/mods/workshop-378160973"
cp -r "$workshop_dir/1185229307" "$install_dir/mods/workshop-1185229307"

# Start the server
bash 4_run_servers.sh
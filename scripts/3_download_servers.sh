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

./steamcmd.sh +force_install_dir "$install_dir" +login anonymous +app_update 343050 validate +quit

cp -r "$workshop_dir/2659976744" "$install_dir/mods/workshop-2659976744"
cp -r "$workshop_dir/2823530744" "$install_dir/mods/workshop-2823530744"
cp -r "$workshop_dir/378160973" "$install_dir/mods/workshop-378160973"
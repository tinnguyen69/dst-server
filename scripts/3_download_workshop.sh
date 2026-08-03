#!/bin/bash

steamcmd_dir="$HOME/steamcmd"
install_dir="$HOME/dontstarvetogether_dedicated_server"
workshop_dir="$HOME/Steam/steamapps/workshop/content/322330"
workshop_ids=(
    1185229307
    1467214795
    2477889104
    2659976744
    2722198225
    2823530744
    3285340146
    3435352667
    378160973
)

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
for workshop_id in "${workshop_ids[@]}"; do
    download_item+=(+workshop_download_item 322330 "$workshop_id" validate)
done
download_item+=(+quit)

"${download_item[@]}" || fail "Failed to download workshop items!"

for workshop_id in "${workshop_ids[@]}"; do
    cp -r "$workshop_dir/$workshop_id" "$install_dir/mods/workshop-$workshop_id"
done

# Start the server
# bash "$HOME/dst-server/scripts/4_run_servers.sh"

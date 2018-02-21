#!/bin/bash
set -e

# thx to https://unix.stackexchange.com/a/35265
function find_in_parents () {
  path="$1"
  name="$2"
  echo "find $name in parent directories: $path"

  while [[ $path != '/' ]]; do
    echo "- $path"
    r=$(find "$path" -maxdepth 1 -mindepth 1 -name "$name")
    # echo ">>>>>>>> $r"
    if ! [ -z "$r" ]; then
      echo "$r"
      return 0
      fi
    # Note: if you want to ignore symlinks, use "$(realpath -s "$path"/..)"
    path="$(readlink -f "$path"/..)"
    done;
    return 1; }


echo $(find_in_parents "$0" "$1")



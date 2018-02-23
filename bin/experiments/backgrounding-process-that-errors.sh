#!/usr/bin/env bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# set -euo pipefail
set -eo pipefail
IFS=$'\n\t'

trap 'echo error!' ERR

# x="$$" ; echo "$x"
# ( sleep 1 ; x="$$" ; echo "$x" ; ls xxxxxxxxxxxxxxxxxx ) &
# ( sleep 1 ; x="$$" ; echo $BASHPID ; ls xxxxxxxxxxxxxxxxxx ) &
# bg

./intershop/bin/experiments/backgrounding-process-that-errors-secondary.sh &
echo "now doing other stuff"
sleep 100

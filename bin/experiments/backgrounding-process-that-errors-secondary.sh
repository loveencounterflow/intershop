#!/usr/bin/env bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# set -euo pipefail
set -eo pipefail
IFS=$'\n\t'

# trap 'echo error!' ERR

# x="$$" ; echo "$x"
# ( sleep 1 ; x="$$" ; echo "$x" ; ls xxxxxxxxxxxxxxxxxx ) &
# ( sleep 1 ; x="$$" ; echo $BASHPID ; ls xxxxxxxxxxxxxxxxxx ) &
# # bg

last_bg_pid="$!"
shell_pid="$$"
bash_pid="$BASHPID"
caller_pid="$PPID"

echo "last_bg_pid   $last_bg_pid"
echo "shell_pid     $shell_pid"
echo "bash_pid      $bash_pid"
echo "caller_pid    $caller_pid"

echo 'secondary', 'helo'
sleep 0.5
# kill $caller_pid
echo 'secondary', 'out'


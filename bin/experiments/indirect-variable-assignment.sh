#!/usr/bin/env bash
# set -ex
set -e
set -u
set -o pipefail


#-----------------------------------------------------------------------------------------------------------
function fooset () {
  local key="$1"
  local value="$2"
  eval "$key=\$value"
}

#-----------------------------------------------------------------------------------------------------------
function list () {
  printenv | grep -E "^[a-z]" || true; }

#-----------------------------------------------------------------------------------------------------------
target_outer=42; export target_outer
target_inner=42; export target_inner
list

#-----------------------------------------------------------------------------------------------------------
echo '---------------------------------'
variable_name='target_outer'
eval "$variable_name='new value'"

fooset 'target_inner' 'fancy new * value'

list


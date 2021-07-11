#!/bin/bash
set -euo pipefail


#===========================================================================================================
# ECHOING FUNCTIONS
#-----------------------------------------------------------------------------------------------------------
grey='\x1b[38;05;240m'
blue='\x1b[38;05;27m'
lime='\x1b[38;05;118m'
orange='\x1b[38;05;208m'
red='\x1b[38;05;124m'
reset='\x1b[0m'
function info () { set +u;  printf "$grey""INTERSHOP ""$blue%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function help () { set +u;  printf "$grey""INTERSHOP ""$lime%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function urge () { set +u;  printf "$grey""INTERSHOP ""$orange%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function warn () { set +u;  printf "$grey""INTERSHOP ""$red%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }


#===========================================================================================================
# CALLING PSQL
#-----------------------------------------------------------------------------------------------------------
function postgres_paged () {
  PAGER="pspg -s17" psql                                                            \
    -U $intershop_db_user -d $intershop_db_name -p $intershop_db_port               \
    --set=intershop_db_user="$intershop_db_user"                                    \
    --set=intershop_db_name="$intershop_db_name"                                    \
    --set QUIET=on --set ON_ERROR_STOP=1                                            \
    "$@"
  }
    # -f "$intershop_guest_path"'/db/update-os-env.sql'                               \

#-----------------------------------------------------------------------------------------------------------
function postgres_unpaged () {
  psql                                                                     \
    -U $intershop_db_user -d $intershop_db_name -p $intershop_db_port               \
    --set=intershop_db_user="$intershop_db_user"                                    \
    --set=intershop_db_name="$intershop_db_name"                                    \
    --set QUIET=on --set ON_ERROR_STOP=1                                            \
    "$@" | cat
  }

#-----------------------------------------------------------------------------------------------------------
# like sudo_postgres_unpaged, but using host database
function sudo_postgres_unpaged_hostdb () {
  sudo -u postgres psql                                                             \
    -d $intershop_db_name -p $intershop_db_port                                     \
    --set=intershop_db_user="$intershop_db_user"                                    \
    --set=intershop_db_name="$intershop_db_name"                                    \
    --set QUIET=on --set ON_ERROR_STOP=1                                            \
    "$@" | cat
  if [[ $? != 0 ]]; then exit 123; fi
  }

#-----------------------------------------------------------------------------------------------------------
function sudo_postgres_unpaged () {
  sudo -u postgres psql                                                             \
    -p $intershop_db_port                                                           \
    --set=intershop_db_user="$intershop_db_user"                                    \
    --set=intershop_db_name="$intershop_db_name"                                    \
    --set QUIET=on --set ON_ERROR_STOP=1                                            \
    "$@" | cat
  if [[ $? != 0 ]]; then exit 123; fi
  }


#===========================================================================================================
# BUILDSCRIPT UTILITIES
#-----------------------------------------------------------------------------------------------------------
function extension_from_path () {
  local base
  base="$(basename "$1")"
  echo ${base##*.}; }

#-----------------------------------------------------------------------------------------------------------
function get_type_of_buildfile () {
  if [[ -x "$1" ]]; then
    echo 'executable'
  else
    extension_from_path "$1";
  fi; }


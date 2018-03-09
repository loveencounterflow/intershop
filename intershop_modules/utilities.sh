#!/bin/bash
set -euo pipefail


#===========================================================================================================
# CALLING PSQL
#-----------------------------------------------------------------------------------------------------------
function postgres_paged () {
  PAGER="postgres-pager -s 6 --less-status-bar" psql                                \
    -U $intershop_db_user -d $intershop_db_name -p $intershop_db_port               \
    --set=intershop_db_user="$intershop_db_user"                                    \
    --set=intershop_db_name="$intershop_db_name"                                    \
    --set=out="$intershop_psql_output_path"                                         \
    --set QUIET=on --set ON_ERROR_STOP=1                                            \
    "$@"
  }
    # -f "$intershop_guest_path"'/db/update-os-env.sql'                               \

#-----------------------------------------------------------------------------------------------------------
function postgres_unpaged () {
  psql                                                                              \
    -U $intershop_db_user -d $intershop_db_name -p $intershop_db_port               \
    --set=intershop_db_user="$intershop_db_user"                                    \
    --set=intershop_db_name="$intershop_db_name"                                    \
    --set=out="$intershop_psql_output_path"                                         \
    --set QUIET=on --set ON_ERROR_STOP=1                                            \
    "$@"
  }
    # -f "$intershop_guest_path"'/db/update-os-env.sql'                               \

#-----------------------------------------------------------------------------------------------------------
function _postgres_unpaged_pre () {
  psql                                                                              \
    -U $intershop_db_user -d $intershop_db_name -p $intershop_db_port               \
    --set=intershop_db_user="$intershop_db_user"                                    \
    --set=intershop_db_name="$intershop_db_name"                                    \
    --set=out="$intershop_psql_output_path"                                         \
    --set QUIET=on --set ON_ERROR_STOP=1                                            \
    "$@"
  }

#-----------------------------------------------------------------------------------------------------------
function _sudo_postgres_unpaged_pre () {
  sudo -u postgres psql                                                             \
    -p $intershop_db_port                                                           \
    --set=intershop_db_user="$intershop_db_user"                                    \
    --set=intershop_db_name="$intershop_db_name"                                    \
    --set=out="$intershop_psql_output_path"                                         \
    --set QUIET=on --set ON_ERROR_STOP=1                                            \
    "$@"
  if [[ $? != 0 ]]; then exit 123; fi
  }

#-----------------------------------------------------------------------------------------------------------
function sudo_postgres_unpaged () {
  sudo -u postgres psql                                                             \
    -p $intershop_db_port                                                           \
    --set=intershop_db_user="$intershop_db_user"                                    \
    --set=intershop_db_name="$intershop_db_name"                                    \
    --set=out="$intershop_psql_output_path"                                         \
    --set QUIET=on --set ON_ERROR_STOP=1                                            \
    -f "$intershop_guest_path"'/db/update-os-env.sql'                               \
    "$@"
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


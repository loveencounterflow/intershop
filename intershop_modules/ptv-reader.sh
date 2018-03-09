#!/bin/bash
set -euo pipefail
# do not change CWD here, this script is sourced
# cd "$( realpath "${BASH_SOURCE[0]}" | xargs dirname )"/..
source "$intershop_guest_bin_path/_trm"


#-----------------------------------------------------------------------------------------------------------
function show () {
  printf "$green%-50s $white%s$reset\n" "$1": "${!1}"; }

#-----------------------------------------------------------------------------------------------------------
function list () {
  declare _LIST_name
  ( for _LIST_name in $( set | grep -o -E '^[a-z_][a-z0-9_]*=' | grep -o -E '^[^=]+' );
    do show "$_LIST_name"; done ) || true; }

#-----------------------------------------------------------------------------------------------------------
_blank_pattern="^[ \t]*$"
_comment_pattern="^[ \t]*#"
_3_fields_pattern="^([^ ]+) +([^ ]+) +(.+)$"

#-----------------------------------------------------------------------------------------------------------
function _match_ptv_line () {
  _ptv_key='';   export _ptv_key
  _ptv_type='';  export _ptv_type
  _ptv_value=''; export _ptv_value
  if [[ $1 =~ $_3_fields_pattern ]]; then
    _ptv_key="${BASH_REMATCH[1]}"
    _ptv_type="${BASH_REMATCH[2]}"
    _ptv_value="${BASH_REMATCH[3]}"
    fi; }

#-----------------------------------------------------------------------------------------------------------
function update_settings_from_ptv_file () {
  echo -e $orange"reading settings from $1"$reset
  #.........................................................................................................
  while IFS='' read -r line || [[ -n "$line" ]]; do
    if [[ $line =~ $_blank_pattern    ]]; then continue; fi
    if [[ $line =~ $_comment_pattern  ]]; then continue; fi
    _match_ptv_line "$line"
    _ptv_key=${_ptv_key//[-\/]/_}
    if [ -z ${!_ptv_key+x} ]; then declare -g "$_ptv_key"=UNDEFINED; fi
    #.......................................................................................................
    # Do recursive interpolations:
    while true; do
      #.....................................................................................................
      # find next embedded variable name of the form 'foo${some/variable/name}bar'
      _ptv_var_name_slashes=$( echo "$_ptv_value" | sed -re 's/^.*?\$\{([a-z_][a-z0-9_\/]*)\}.*$/\1/g' )
      ### TAINT should first match generously (e.g. find all ${...} stretches), then complain in case
      ### variable name doesnt match stricter pattern; this to avoid silent failures from spurious spaces etc
      #.....................................................................................................
      # break if no embedded variable name was found:
      if [[ "$_ptv_var_name_slashes" == '' || "$_ptv_var_name_slashes" == "$_ptv_value" ]]; then
        declare -g "$_ptv_key"="$_ptv_value"
        export "$_ptv_key"
        break
        fi
      #.....................................................................................................
      # find the shell variable name by replacing slashes with underscores; exit with error if
      # that variable is unknown:
      _ptv_var_name=$( echo "$_ptv_var_name_slashes" | sed -re 's/[-\/]/_/g' )
      if [ -z ${!_ptv_var_name+x} ]; then
        echo -e $red"found unknown variable '$_ptv_var_name' when trying to resolve"$reset
        echo -e $red"$line"$reset
        exit 2
        fi
      #.....................................................................................................
      # find the replacement value, update loop variable, and publish the new value (which may in turn spell
      # out )
      _ptv_var_value="${!_ptv_var_name}"
      _ptv_value=${_ptv_value/\$\{$_ptv_var_name_slashes\}/$_ptv_var_value}
      declare -g "$_ptv_key"="$_ptv_value"
      export "$_ptv_key"
      break
      done
    #.......................................................................................................
    done < "$1"; }


### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
# demo below


# declare -g intershop_host_path=/the/intershop/host/path
# intershop_guest_configuration_path=/home/flow/io/mingkwai-rack/mojikura3-model/intershop/intershop.ptv
# intershop_host_configuration_path=/home/flow/io/mingkwai-rack/mojikura3-model/intershop.ptv
# update_settings_from_ptv_file "$intershop_guest_configuration_path"
# update_settings_from_ptv_file "$intershop_host_configuration_path"
# list
# echo -e '19811-2' $cyan"$intershop_host_name"$reset
# echo -e '19811-2' $cyan"$intershop_db_name"$reset
# exit



# my_variable_name=mojikura_jzrds_path
# export my_variable_name
# # ${!my_variable_name}=42
# # declare $my_variable_name=42
# # list
# # exit

# while true; do
#   show "$my_variable_name"
#   _ptv_var_name=$( echo ${!my_variable_name} | sed -re 's/^.*?\$\{([a-z_][a-z0-9_]*)\}.*$/\1/g' )
#   if [[ $_ptv_var_name == '' || $_ptv_var_name == ${!my_variable_name} ]]; then break; fi
#   _ptv_var_value="${!_ptv_var_name}"
#   declare "$my_variable_name"=${!my_variable_name/\$\{$_ptv_var_name\}/$_ptv_var_value}
#   done
# # show mojikura_jzrds_path
# # list
# exit

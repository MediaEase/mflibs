#!/usr/bin/env bash
################################################################################
# @file_name: log
# @version: 1.0.51
# @project_name: mflibs
# @brief: a library for logging functions
#
# @author: Jamie Dobbs (mschf), Thomas Chauveau (tomcdj71)
# @author_contact: jamie.dobbs@mschf.dev, contact.tomc@yahoo.fr
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2024, Jamie Dobbs, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# @description: initialize log library
# @return_code: 1 unable to touch log file
# @internal
################################################################################
mflibs::log::init() {
  declare mflibs_log_base
  mflibs_log_base="/var/log/mediaease"
  [[ -z "${mflibs_log_file}" ]] && declare -g mflibs_log_file="${mflibs_log_base}/${BASH_SOURCE[-1]##*/}"
  trap 'LAST_COMMAND="$BASH_COMMAND"; mflibs::log::handle_command "$LAST_COMMAND"' DEBUG
  if [[ ! -d "$(dirname "${mflibs_log_file}")" ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - creating log location: $(dirname "${mflibs_log_file}")\n"
    mkdir -p "$(dirname "${mflibs_log_file}")"
  fi
  if [[ -f "${mflibs_log_file}" && $(wc -c "${mflibs_log_file}" | awk '{print $1}') -gt 25000 ]]; then
    timestamp=$(date "+%Y-%m-%d-%H-%M-%S")
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - rotating ${mflibs_log_file} to ${mflibs_log_file}-$timestamp\n"
    mv -f "${mflibs_log_file}" "${mflibs_log_file}-$timestamp"
  fi
  touch "${mflibs_log_file}" || { echo -ne "[$(tput setaf 1)ERROR$(tput sgr0)][1] - unable to touch ${mflibs_log_file}\n" && exit 1; }
  printf "\n### %s ###\n" "$(date "+%Y-%m-%d %R:%S")" >>"${mflibs_log_file}"
  export MFLIBS_LOG_LOCATION="${mflibs_log_file}"
  if [[ $(du -s "${mflibs_log_base}" | awk '{print $1}') -gt 100000 ]]; then
    find "${mflibs_log_base}" -type f -name "$(basename "${mflibs_log_file}")-*" -mtime +2 -exec rm -f {} \;
  fi
}

################################################################################
# @description: runs and logs command
# @arg 1: command to log
# @example:
#   mflibs::log "echo hi"
mflibs::log() {
  local command="$1"

  if [[ " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    # Debug Mode: Log command before execution
    echo "$(date "+%Y-%m-%d %H:%M:%S") [DEBUG] Executing: $command" >> "${mflibs_log_file}"
    { eval "$command" 2>&1; } |& tee -a "${mflibs_log_file}"
  
  elif [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
    # Verbose Mode: Only print output, no logging
    eval "$command" 2>&1

  else
    # Normal Mode: Log output but don’t print to terminal
    eval "$command" >>"${mflibs_log_file}" 2>&1
  fi
}

################################################################################
# @description: handles command logging
# @arg 1: command to log
# @example:
#   mflibs::log::handle_command "echo hi"
mflibs::log::handle_command() {
  local command="$1"
  local timestamp
  timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
  case "$command" in
    *" > /dev/null"*|*" 2> /dev/null"*|*" &>/dev/null"*|*" </dev/null"*) return ;;
    cat*"/proc/"*|cat*"/sys/"*|cat*"/dev/"*|echo*"/proc/"*|echo*"/sys/"*) return ;;
    echo*"="*|echo*"/tmp/"*|echo*"/run/"*) return ;;
    history*|trap*|unset*|alias*|unalias*|type*|set*) return ;;
    declare*|export*|local*) return ;;
  esac
  if [[ "$command" =~ (password|vault|key|user) ]]; then
    return
  fi
  echo "$timestamp [CMD] $command" >> "${mflibs_log_file}"
  if [[ "$command" =~ ^wget ]]; then
    local wget_cmd="$command"
    if [[ " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
      wget_cmd=$(echo "$wget_cmd" | sed -E "s/ -q//g")
      wget_cmd+=" -v"
      echo "$timestamp [DEBUG] $wget_cmd" >> "${mflibs_log_file}"
    elif [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
      wget_cmd=$(echo "$wget_cmd" | sed -E "s/ -q//g")
      wget_cmd+=" -nv"
      echo "$timestamp [VERBOSE] $wget_cmd" >> "${mflibs_log_file}"
    else
      wget_cmd=$(echo "$wget_cmd" | sed -E "s/ -q//g")
      wget_cmd+=" -q"
      echo "$timestamp [CMD] $wget_cmd" >> "${mflibs_log_file}"
    fi
    return
  fi
  if [[ "$command" =~ ^apt || "$command" =~ ^apt-get ]]; then
    local apt_cmd="$command"
    if [[ " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
      apt_cmd=$(echo "$apt_cmd" | sed -E "s/ -qq//g")
      apt_cmd+=" -V"
      echo "$timestamp [DEBUG] $apt_cmd" >> "${mflibs_log_file}"
    elif [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
      apt_cmd=$(echo "$apt_cmd" | sed -E "s/ -qq//g")
      apt_cmd+=" -q"
      echo "$timestamp [VERBOSE] $apt_cmd" >> "${mflibs_log_file}"
    else
      apt_cmd=$(echo "$apt_cmd" | sed -E "s/ -qq//g")
      apt_cmd+=" -qq"
      echo "$timestamp [CMD] $apt_cmd" >> "${mflibs_log_file}"
    fi
    return
  fi
}

################################################################################
# @description: runs functions in the required order
################################################################################
mflibs::log::init

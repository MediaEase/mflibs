#!/usr/bin/env bash
################################################################################
# @file_name: log
# @version: 1.0.51
# @project_name: mflibs
# @brief: a library for logging functions
#
# @author: Jamie Dobbs (mschf)
# @author_contact: jamie.dobbs@mschf.dev
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2022, Jamie Dobbs
# All rights reserved.
################################################################################

################################################################################
# @description: initialize log library
# @return_code: 1 unable to touch log file
# @internal
################################################################################
mflibs::log::init() {
  declare mflibs_log_base;mflibs_log_base="/opt/MediaEase/logs"; 
  [[ -z "${mflibs_log_file}" ]] && declare -g mflibs_log_file="${mflibs_log_base}/${BASH_SOURCE[-1]##*/}"
  if [[ ! -d "$(dirname "${mflibs_log_file}")" ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - creating log location: $(dirname "${mflibs_log_file}")\n"
    mkdir -p "$(dirname "${mflibs_log_file}")"
  fi
  if [[ -f "${mflibs_log_file}" && $(wc -c "${mflibs_log_file}" | awk '{print $1}') -gt 10000 ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - rotating ${mflibs_log_file} to ${mflibs_log_file}.1\n"
    mv -f "${mflibs_log_file}" "${mflibs_log_file}.1"
  fi
  touch "${mflibs_log_file}" || { echo -ne "[$(tput setaf 1)ERROR$(tput sgr0)][1] - unable to touch ${mflibs_log_file}\n" && exit 1; }
  printf "\n### %s ###\n" "$(date "+%Y-%m-%d %R:%S")" >> "${mflibs_log_file}"
  export MFLIBS_LOG_LOCATION="${mflibs_log_file}"
}

################################################################################
# @description: runs and logs command
# @arg 1: command to log
# @example:
#   mflibs::log "echo hi"
################################################################################
mflibs::log() {
  if [[ ! " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
    ($1 >> "${mflibs_log_file}" 2>&1)
  else
    $1 |& tee -a "${mflibs_log_file}"
  fi
}

################################################################################
# @description: runs functions in the required order
################################################################################
mflibs::log::init

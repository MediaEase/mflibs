#!/usr/bin/env bash
################################################################################
# @file_name: status
# @version: 1.0.11
# @project_name: mflibs
# @brief: a library for status handling
#
# @author: Jamie Dobbs (mschf)
# @author_contact: jamie.dobbs@mschf.dev
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2022, Jamie Dobbs
# All rights reserved.
################################################################################

################################################################################
# @description: outputs error to term
# @arg $1: error message
# @example:
#   mflibs::status::error "error_message" 1
################################################################################
mflibs::status::error() {
  declare message=${1:-"an unspecified error occurred"}
  declare mf_error=${2:-1}
  message=${message//$HOME/\~}
  # if verbose is set, print the stack trace
  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
    echo -ne "\033[0;38;5;203m[ERROR]\e[0m[$mf_error] - $message\n" >&2
    echo -ne "\033[0;38;5;203m[ERROR]\e[0m[$mf_error] - stack trace:\n" >&2
    local i=0
    while caller $i; do ((i++)); done
  else
    echo -ne "\033[0;38;5;203m$message\n" >&2
  fi
}

################################################################################
# @description: outputs error to term and exits with provided return
# @arg $1: error message
# @arg $2: exit code
# @example:
#   mflibs::status::kill "error_message" 1
################################################################################
mflibs::status::kill() {
  mflibs::status::error "$1" "$2"; exit "${2:-1}"
}

################################################################################
# @description: outputs warn to term
# @arg $1: error message
# @example:
#   mflibs::status::warn "warning_message" 1
################################################################################
mflibs::status::warn() {
  declare message=${1:-"an unspecified error occurred"}
  declare mf_error=${2:-1}
  message=${message//$HOME/\~}
  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
    echo -ne "\033[0;38;5;208m[WARN]\e[0m[$mf_error] - $message\n" >&2
  else
    echo -ne "\033[0;38;5;208m$message\n" >&2
  fi
}

################################################################################
# @description: outputs success to term
# @arg $1: success message
# @example:
#   mflibs::status::success "success_message"
################################################################################
mflibs::status::success() {
  declare message=${1:-"command completed successfully"}
  message=${message//$HOME/\~}
  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
    echo -ne "\033[0;38;5;34m[SUCCESS]\e[0m - $message\n"
  else 
    echo -ne "\033[0;38;5;34m$message\n"
  fi
}

################################################################################
# @description: outputs info to term
# @arg $1: info message
# @example:
#   mflibs::status::info "info_message"
################################################################################
mflibs::status::info() {
  declare message=${1:-"information not specified"}
  message=${message//$HOME/\~}
  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]]; then
    echo -ne "\033[0;38;5;44m[INFO]\e[0m - $message\n"
  else 
    echo -ne "\033[0;38;5;44m$message\n"
  fi
}

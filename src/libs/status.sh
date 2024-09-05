#!/usr/bin/env bash
################################################################################
# @file_name: status
# @version: 1.0.11
# @project_name: mflibs
# @brief: a library for status handling
#
# @author: Jamie Dobbs (mschf), Thomas Chauveau (tomcdj71)
# @author_contact: jamie.dobbs@mschf.dev, contact.tomc@yahoo.fr
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2024, Jamie Dobbs, Thomas Chauveau
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
  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo -ne "[$(tput setaf 1)ERROR$(tput sgr0)][$mf_error] - $message\n" >&2
    echo -ne "[$(tput setaf 1)ERROR$(tput sgr0)][$mf_error] - stack trace:\n" >&2
    local i=0
    while caller $i; do ((i++)); done
  else
    echo -ne "$(tput setaf 1)$message\n" >&2
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
  mflibs::status::error "$1" "$2"
  exit "${2:-1}"
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
  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo -ne "$(tput sgr0)[$(tput setaf 3)WARN$(tput sgr0)][$mf_error] - $message\n" >&2
  else
    echo -ne "$(tput setaf 3)$message\n" >&2
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
  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo -ne "$(tput sgr0)[$(tput setaf 2)SUCCESS$(tput sgr0)] - $message\n"
  else
    echo -ne "$(tput setaf 2)$message\n"
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
  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo -ne "$(tput sgr0)[$(tput setaf 4)INFO$(tput sgr0)] - $message\n"
  else
    echo -ne "$(tput setaf 6)$message\n"
  fi
}

################################################################################
# @description: outputs header to term
# @arg $1: header message
# @example:
#   mflibs::status::header "header_message"
################################################################################
mflibs::status::header() {
  declare message=${1:-"header not specified"}
  message=${message//$HOME/\~}
  if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]]; then
    echo -ne "$(tput sgr0)[$(tput setaf 7)HEADER$(tput sgr0)] - $message\n"
  else
    echo -ne "$(tput setaf 7)$message\n"
  fi
}

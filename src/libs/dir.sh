#!/usr/bin/env bash
################################################################################
# @file_name: dir
# @version: 1.1.37
# @project_name: mflibs
# @brief: the dir library handles directory manipulation
#
# @author: Jamie Dobbs (mschf), Thomas Chauveau (tomcdj71)
# @author_contact: jamie.dobbs@mschf.dev, contact.tomc@yahoo.fr
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2024, Jamie Dobbs, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# @description: creates and moves into directory
# @example:
#   mflibs::dir::mkcd "newdir"
# @arg $1: dir
# @return_code: 0 success
# @return_code: 1 mkdir fail
# @return_code: 2 cd fail
# @return_code: 3 missing arguments
################################################################################
mflibs::dir::mkcd() {
  if [[ $# = 0 ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)3$(tput sgr0)]: ${FUNCNAME[0]} is missing arguments\n" >&2
    return 3
  fi
  declare directory="${1}"
  mkdir -p -- "${directory}" || return 1
  cd -- "${directory}" || return 2
}

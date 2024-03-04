#!/usr/bin/env bash
################################################################################
# @file_name: zen
# @version: 1.1.380
# @project_name: mflibs
# @description: a loader for the mflibs libraries
#
# @author: Jamie Dobbs (mschf)
# @author_contact: jamie.dobbs@mschf.dev
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2022, Jamie Dobbs
# All rights reserved.
################################################################################

################################################################################
# @description: checks for valid bash version and sets required variables
# @noargs
# @return_code: 1 bash version mismatch
# @internal
################################################################################
zen::environment::init() {
    [[ ${BASH_VERSINFO[0]} -lt 4 ]] && printf "exiting: mflibs requires bash version 4 or greater" && exit 1
    declare mflibs_base_location; declare -g mflibs_lib_location mflibs_custom_location
    mflibs_base_location="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"
    mflibs_base_location="${mflibs_base_location%/*}"
    mflibs_lib_location="${mflibs_base_location}/libs"
    # mflibs_custom_location="${mflibs_base_location}/custom"
    mediaease_base_location="/opt/MediaEase/MediaEase"
}

################################################################################
# @description: checks for valid libs and imports them
# @arg $1: libs to import
# @example: mflibs::import "lib1,lib2,lib3"
# @return_code: 2 lib not readable
# shellcheck disable=2068,1090
################################################################################
zen::import() {
    local loaded_libraries=()
    local failed_libraries=()
    echo "Importing libraries..."
    [[ $* =~ "verbose" ]] && declare -xga MFLIBS_LOADED+=("verbose") && echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - verbosity enabled\n"
    
    for l in ${@//,/ }; do
        [[ $l == "verbose" ]] && continue
        local library_path=""
        if [[ -f ${mflibs_lib_location}/${l}.sh ]]; then
            library_path="${mflibs_lib_location}/${l}.sh"
        elif [[ -f ${mediaease_base_location}/scripts/src/modules/${l}.sh ]]; then
            library_path="${mediaease_base_location}/scripts/src/modules/${l}.sh"
        fi

        if [[ -n $library_path ]]; then
            . "$library_path"
            loaded_libraries+=("$l")
        else
            failed_libraries+=("$l")
        fi
    done
    if [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && [[ ${#loaded_libraries[@]} -gt 0 ]]; then
        echo -ne "$(tput sgr0)[$(tput setaf 2)SUCCESS$(tput sgr0)] - loaded libraries: ${loaded_libraries[*]}\n"
    fi
    if [[ ${#failed_libraries[@]} -gt 0 ]]; then
        echo -ne "$(tput sgr0)[$(tput setaf 3)WARN$(tput sgr0)] - libraries not loaded: ${failed_libraries[*]}\n" 
    fi
    if [[ " ${MFLIBS_LOADED[*]} " =~ verbose ]] && [[ " ${loaded_libraries[*]} " =~ log ]]; then
        echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - logging to ${MFLIBS_LOG_LOCATION}\n"
    fi
}

################################################################################
# @description: runs functions in the required order
################################################################################
zen::environment::init

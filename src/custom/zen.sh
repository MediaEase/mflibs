#!/usr/bin/env bash
################################################################################
# @file_name: zen
# @version: 1.1.380
# @project_name: mflibs
# @description: a loader for the mflibs libraries
#
# @author: Jamie Dobbs (mschf), Thomas Chauveau (tomcdj71)
# @author_contact: jamie.dobbs@mschf.dev, contact.tomc@yahoo.fr
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2024, Jamie Dobbs, Thomas Chauveau
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
    declare mflibs_base_location
    declare -g mflibs_lib_location mflibs_custom_location
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
    [[ $* =~ "verbose" ]] && declare -xga MFLIBS_LOADED+=("verbose") && echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - verbosity enabled\n"
    [[ $* =~ "debug" ]] && declare -xga MFLIBS_LOADED+=("debug") && echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - debug enabled\n"

    for lib in ${@//,/ }; do
        [[ $lib == "verbose" || $lib == "debug" ]] && continue
        local library_path=""
        if [[ -f ${mflibs_lib_location}/${lib}.sh ]]; then
            library_path="${mflibs_lib_location}/${lib}.sh"
        elif [[ -f ${mediaease_base_location}/zen/src/modules/${lib}.sh ]]; then
            library_path="${mediaease_base_location}/zen/src/modules/${lib}.sh"
        fi

        if [[ -n $library_path ]]; then
            . "$library_path"
            loaded_libraries+=("$lib")
        else
            failed_libraries+=("$lib")
        fi
    done
    if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && [[ ${#loaded_libraries[@]} -gt 0 ]]; then
        echo -ne "$(tput sgr0)[$(tput setaf 2)SUCCESS$(tput sgr0)] - loaded libraries: ${loaded_libraries[*]}\n"
    fi
    if [[ ${#failed_libraries[@]} -gt 0 ]]; then
        echo -ne "$(tput sgr0)[$(tput setaf 3)WARN$(tput sgr0)] - libraries not loaded: ${failed_libraries[*]}\n"
    fi
    if [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && [[ " ${loaded_libraries[*]} " =~ log ]]; then
        echo -ne "$(tput sgr0)[$(tput setaf 6)INFO$(tput sgr0)] - logging to ${MFLIBS_LOG_LOCATION}\n"
    fi
}

################################################################################
# @description: runs functions in the required order
################################################################################
zen::environment::init

#!/usr/bin/env bash
# shellcheck source=/dev/null
################################################################################
# @file_name: distro
# @version: 1.1.49
# @project_name: mflibs
# @brief: a library for distro related functions
#
# @author: Jamie Dobbs (mschf), Thomas Chauveau (tomcdj71)
# @author_contact: jamie.dobbs@mschf.dev, contact.tomc@yahoo.fr
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2024, Jamie Dobbs, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# @description: identify linux codename
# @example:
#   mflibs::distro::codename
# @noargs
# @return_code: 0 success
# @return_code: 1 unable to detect
################################################################################
mflibs::distro::codename() {
  declare distro_codename
  if type lsb_release >/dev/null 2>&1; then
    distro_codename=$(lsb_release -cs)
  elif [[ -f /etc/os-release ]]; then
    source "/etc/os-release"
    distro_codename="${VERSION_CODENAME}"
  elif [[ -f /etc/lsb-release ]]; then
    source /etc/lsb-release
    distro_codename="${DISTRIB_CODENAME}"
  else
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)1$(tput sgr0)]: unable to detect code name\n" >&2
    return 1
  fi
  printf -- "%s" "${distro_codename}"
}

################################################################################
# @description: identify linux version
# @noargs
# @example:
#   mflibs::distro::version
# @return_code: 0 success
# @return_code: 1 unable to detect
# @attribution: labbots, MIT
################################################################################
mflibs::distro::version() {
  declare distro_version
  if type lsb_release >/dev/null 2>&1; then
    distro_version=$(lsb_release -sr)
  elif [[ -f /etc/os-release ]]; then
    source "/etc/os-release"
    distro_version="${VERSION_ID}"
  elif [[ -f /etc/lsb-release ]]; then
    source /etc/lsb-release
    distro_version="${DISTRIB_RELEASE}"
  else
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)1$(tput sgr0)]: unable to detect distro version\n" >&2
    return 1
  fi
  printf -- "%s" "${distro_version}"
}

################################################################################
# @description: identify linux distro
# @noargs
# @example:
#   mflibs::distro::name
# @return_code: 0 success
# @return_code: 1 unable to detect distro codename
# @return_code: 2 unable to detect distro version
# @return_code: 3 unable to identify system information from /etc/os-release
################################################################################
mflibs::distro::report() {
  declare -g os_name os_version os_codename packagetype
  # shellcheck disable=SC2034
  os_codename=$(mflibs::distro::codename) || {
    printf -- "Unable to detect distro codename.\n"
    return 1
  }
  os_version=$(mflibs::distro::version) || {
    echo "Unable to detect distro version."
    printf -- "Unable to detect distro version.\n"
    return 2
  }
  if [[ -f /etc/os-release ]]; then
    source "/etc/os-release"
    os_name="${ID}"
    packagetype="Unknown"

    case "${ID}" in
    ubuntu | debian | raspbian)
      packagetype="apt"
      ;;
    centos | rhel | fedora | amzn)
      packagetype="dnf"
      [[ "${VERSION_ID%%.*}" = "7" ]] && packagetype="yum"
      ;;
    arch | manjaro)
      packagetype="pacman"
      ;;
    opensuse* | sles)
      packagetype="zypper"
      ;;
    alpine)
      packagetype="apk"
      ;;
    *)
      packagetype="Not supported"
      ;;
    esac
  else
    printf -- "Unable to identify system information from /etc/os-release.\n"
    return 3
  fi
}

################################################################################
# @description: Checks if the OS is Ubuntu 22+ or Debian 12+ with apt package management
# @noargs
# @return_code: 0 if supported
# @return_code: 1 if unsupported
# @return_code: 2 if neither curl nor wget is available
# @return_code: 3 if unsupported OS version
################################################################################
mflibs::distro::check() {
  mflibs::distro::report
  if [[ "${packagetype}" != "apt" ]]; then
    printf -- "Unsupported package manager: %s on %s %s\n" "${packagetype}" "${os_name}" "${os_version}"
    return 1
  fi
  if [[ "${os_name}" = "ubuntu" && "${os_version}" -ge 22 ]] || [[ "${os_name}" = "debian" && "${os_version}" -ge 12 ]]; then
    if mflibs::verify::command "curl"; then
      CURL="curl -fsSL"
      STAND_CURL="curl"
    elif mflibs::verify::command "wget"; then
      CURL="wget -qO- --content-on-error"
      STAND_CURL="wget"
    else
      printf -- "Neither curl nor wget is available, which are required for downloading.\n"
      return 2
    fi
    export STAND_CURL CURL
    return 0
  else
    printf -- "Unsupported OS version: %s %s (Requires Ubuntu 22+ or Debian 12+)\n" "${os_name}" "${os_version}"
    return 3
  fi
}

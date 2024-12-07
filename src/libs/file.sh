#!/usr/bin/env bash
################################################################################
# @file_name: file
# @version: 1.1.25
# @project_name: mflibs
# @brief: a library for file functions
#
# @author: Jamie Dobbs (mschf), Thomas Chauveau (tomcdj71)
# @author_contact: jamie.dobbs@mschf.dev, contact.tomc@yahoo.fr
#
# @license: BSD-3 Clause (Included in LICENSE)
# Copyright (C) 2021-2024, Jamie Dobbs, Thomas Chauveau
# All rights reserved.
################################################################################

################################################################################
# @description: extracts based on extension
# @example:
#   mflibs::file::extract file.tar.gz
# @arg $1: file to extract
# @return_code: 0 success
# @return_code: 1 unable to extract
# @return_code: 2 invalid amount of arguments
# @return_code: 3 file does not exist
################################################################################
mflibs::file::extract() {
  if [[ $# -ne 1 ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)2$(tput sgr0)]: ${FUNCNAME[0]} is missing arguments\n" >&2
    return 2
  fi
  if [[ ! -f "$1" ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)3$(tput sgr0)]: $1 does not exist" >&2
    return 3
  fi
  case $1 in
  *.tar | *.tar.xz | *.tar.zst) tar -xf "$1" && return 0 ;;
  *.tar.bz2 | *.tbz2) tar -jxf "$1" --strip-components=1 && return 0 ;;
  *.tar.gz | *.tgz) tar -zxf "$1" --strip-components=1 && return 0 ;;
  *.bz2) bunzip2 "$1" && return 0 ;;
  *.gz) gunzip "$1" && return 0 ;;
  *.gpg) gpg -d "$1" | tar -xf - && return 0 ;;
  *.rar) 7z x "$1" && return 0 ;;
  *.zip) unzip -q "$1" && return 0 ;;
  *.7z) 7z x "$1" && return 0 ;;
  *.deb) dpkg -i "$1" | less && return 0 ;;
  esac
  [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)1$(tput sgr0)]: unable to extract\n" >&2
  return 1
}

################################################################################
# @description: Copies a file or directory and handles errors with a custom message.
# @example:
#   mflibs::file::copy "/path/to/source" "/path/to/destination"
# @arg $1: source file or directory
# @arg $2: destination file or directory
# @return_code: 0 success
# @return_code: 1 copy failed
# @return_code: 2 invalid amount of arguments
# @return_code: 3 source file or directory does not exist
################################################################################
mflibs::file::copy() {
  if [[ $# -ne 2 ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)2$(tput sgr0)]: ${FUNCNAME[0]} is missing arguments\n" >&2
    return 2
  fi
  local source="$1"
  local destination="$2"
  if [[ ! -d "$(dirname "$destination")" ]]; then
    if ! mkdir -p "$(dirname "$destination")"; then
      [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)1$(tput sgr0)]: Unable to create directory $(dirname "$destination")\n" >&2
      return 1
    fi
  fi
  if [[ ! -e "$source" ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)3$(tput sgr0)]: $source does not exist\n" >&2
    return 3
  fi
  if [[ -d "$source" ]]; then
    cp -pR "$source"/* "$destination" || echo -ne "[$(tput setaf 1)1$(tput sgr0)]: Unable to copy $source to $destination\n" >&2
  else
    cp -p "$source" "$destination" || echo -ne "[$(tput setaf 1)1$(tput sgr0)]: Unable to copy $source to $destination\n" >&2
  fi
  [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 2)0$(tput sgr0)]: Copied $source to $destination\n"
  return 0
}

################################################################################
# @description: Moves a file or directory and handles errors with a custom message.
# @example:
#   mflibs::file::move "/path/to/source" "/path/to/destination"
# @arg $1: source file or directory
# @arg $2: destination file or directory
# @return_code: 0 success
# @return_code: 1 move failed
# @return_code: 2 invalid amount of arguments
# @return_code: 3 source file or directory does not exist
################################################################################
mflibs::file::move() {
  if [[ $# -ne 2 ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)2$(tput sgr0)]: ${FUNCNAME[0]} is missing arguments\n" >&2
    return 2
  fi
  local source="$1"
  local destination="$2"
  if [[ ! -e "$source" ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)3$(tput sgr0)]: $source does not exist\n" >&2
    return 3
  fi
  mv "$source" "$destination" || echo -ne "[$(tput setaf 1)1$(tput sgr0)]: Unable to move $source to $destination\n" >&2
  return 0
}

################################################################################
# @description: Archives a file or directory based on the given extension.
#               Creates the destination directory if it doesn't exist.
#               Appends to the archive if it already exists.
# @example:
#   mflibs::file::inflate "myfile.txt" "backup.tar.gz" "/root/backups"
#   mflibs::file::inflate "mydirectory" "backup.zip" "/root/backups"
# @arg $1: file or directory to archive
# @arg $2: name.extension for the output archive
# @arg $3: output directory where the archive will be saved
# @return_code: 0 success
# @return_code: 1 unable to archive
# @return_code: 2 invalid number of arguments
# @return_code: 3 file or directory does not exist
################################################################################
mflibs::file::inflate() {
  if [[ $# -ne 3 ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)2$(tput sgr0)]: ${FUNCNAME[0]} has incorrect number of arguments\n" >&2
    return 2
  fi
  local input_path="$1"
  local archive_name="$2"
  local output_dir="$3"
  local output_path="$output_dir/$archive_name"
  if [[ ! -e "$input_path" ]]; then
    [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)3$(tput sgr0)]: $input_path does not exist\n" >&2
    return 3
  fi
  if [[ ! -d "$output_dir" ]]; then
    if ! mkdir -p "$output_dir"; then
      [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)1$(tput sgr0)]: Unable to create directory $output_dir\n" >&2
      return 1
    fi
  fi
  if [[ -f "$output_path" ]]; then
    case $output_path in
    *.tar) if ! tar -rf "$output_path" -C "$(dirname "$input_path")" "$(basename "$input_path")"; then return 1; fi ;;
    *.tar.xz | *.tar.zst | *.tar.bz2 | *.tbz2 | *.tar.gz | *.tgz)
      if ! tar --append --file="$output_path" -C "$(dirname "$input_path")" "$(basename "$input_path")"; then return 1; fi
      ;;
    *.rar) if ! rar a "$output_path" "$input_path"; then return 1; fi ;;
    *.zip) if ! zip -rqu "$output_path" "$input_path"; then return 1; fi ;;
    *.7z) if ! 7z u "$output_path" "$input_path"; then return 1; fi ;;
    *)
      [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)1$(tput sgr0)]: unable to append to archive\n" >&2
      return 1
      ;;
    esac
  else
    case $output_path in
    *.tar) if ! tar -cf "$output_path" -C "$(dirname "$input_path")" "$(basename "$input_path")"; then return 1; fi ;;
    *.tar.xz) if ! tar -cJf "$output_path" -C "$(dirname "$input_path")" "$(basename "$input_path")"; then return 1; fi ;;
    *.tar.zst) if ! tar --zstd -cf "$output_path" -C "$(dirname "$input_path")" "$(basename "$input_path")"; then return 1; fi ;;
    *.tar.bz2 | *.tbz2) if ! tar -cjf "$output_path" -C "$(dirname "$input_path")" "$(basename "$input_path")"; then return 1; fi ;;
    *.tar.gz | *.tgz) if ! tar -czf "$output_path" -C "$(dirname "$input_path")" "$(basename "$input_path")"; then return 1; fi ;;
    *.rar) if ! rar a "$output_path" "$input_path"; then return 1; fi ;;
    *.zip) if ! zip -rq "$output_path" "$input_path"; then return 1; fi ;;
    *.7z) if ! 7z a "$output_path" "$input_path"; then return 1; fi ;;
    *)
      [[ " ${MFLIBS_LOADED[*]} " =~ verbose || " ${MFLIBS_LOADED[*]} " =~ debug ]] && echo -ne "[$(tput setaf 1)1$(tput sgr0)]: unable to create archive\n" >&2
      return 1
      ;;
    esac
  fi

  return 0
}

################################################################################
# @description: loads a yaml file and returns a value based on a key
# @example:
#   mflibs::file::load::yaml::key file.yaml key
# @arg $1: file to load
# @arg $2: key to extract
# @stdout: value of key
################################################################################
mflibs::file::load::yaml::key() {
  local file="$1"
  local key="$2"
  local value
  value=$(yq r "$file" "$key")
  echo "$value"
}

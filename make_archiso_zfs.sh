#!/bin/sh

################################################################################
# purpose:   build a new archiso with the zfs kernel package on it
# args/opts: see usage (run with -h option)
################################################################################

# global vars:
build_dir='archiso_build'               # build dir for creating archiso
clean_dir='false'                       # clean build dir before any ops
archiso_dev=''                          # the thumb drive path (e.g. /dev/sdb)
use_git_kernel_version='false'          # use the '-git' version of zfs kernel
kernel_pkg=''                           # user-selected kernel to use in archiso
extra_packages=''                       # extra packages to install to archiso

print_usage() {
  echo 'USAGE:'
  echo "  $(basename "${0}")  -h"
  echo "  sudo  $(basename "${0}")  [  [-L|-S|-H|-Z|-D]  [-g]  ]  [-b <build_dir>]"
  echo '                             [-p <pkg1,pkg2,...>]  [-f <pkgs_file>]'
  echo '                             [-d <device>]'
  echo 'OPTIONS:'
  echo '  -h, --help'
  echo '      print this help message'
  echo '  -c --clean-build-dir'
  echo '      remove archiso build dir before performing any operations'
  echo '  -L, --zfs-kernel-lts'
  echo '      use archzfs-linux-lts kernel package (default option)'
  echo '  -S, --zfs-kernel-stable'
  echo '      use archzfs-linux kernel package'
  echo '  -H, --zfs-kernel-hardened'
  echo '      use archzfs-linux-hardened kernel package'
  echo '  -Z, --zfs-kernel-zen'
  echo '      use archzfs-linux-zen kernel package'
  echo '  -D, --zfs-kernel-dkms'
  echo '      use archzfs-linux-dkms kernel package'
  echo '  -g, --zfs-kernel-use-git-version'
  echo '      use git version of selected kernel (e.g. archzfs-linux-git)'
  echo '  -b <build_dir>, --set-build-dir=<build_dir>'
  echo '      set archiso build dir (default is '\''archiso_build'\'')'
  echo '  -p <pkg1,pkg2,...>, --extra-packages=<pkg1,pkg2,...>'
  echo '      extra packages to install to iso'
  echo '  -f <pkgs_file>, --extra-packages-file=<pkgs_file>'
  echo '      extra packages to install to iso (from file, one pkg per line)'
  echo '  -d <device>, --write-iso-to-device=<device>'
  echo '      write built iso to device (e.g. device /dev/sdb)'
  echo 'EXIT CODES:'
  echo '    0  ok'
  echo '    1  usage, arguments, or options error'
  echo '    5  archiso build error'
  echo '   10  archiso write-to-device error'
  echo '  255  unknown error'
  exit "${1}"
}

get_cmd_opts_and_args() {
  while getopts ':hcLSHZDgb:f:p:d:-:' option; do
    case "${option}" in
      h)  handle_help ;;
      c)  handle_clean_build_dir ;;
      L)  handle_zfs_kernel_lts ;;
      S)  handle_zfs_kernel_stable ;;
      H)  handle_zfs_kernel_hardened ;;
      Z)  handle_zfs_kernel_zen ;;
      D)  handle_zfs_kernel_dkms ;;
      g)  handle_zfs_kernel_use_git_version ;;
      b)  handle_set_build_dir "${OPTARG}" ;;
      f)  handle_extra_packages_from_file "${OPTARG}" ;;
      p)  handle_extra_packages "${OPTARG}" ;;
      d)  handle_write_iso_to_device "${OPTARG}" ;;
      -)  LONG_OPTARG="${OPTARG#*=}"
          case ${OPTARG} in
            help)                         handle_help ;;
            help=*)                       handle_illegal_option_arg "${OPTARG}" ;;
            clean-build-dir)              handle_clean_build_dir ;;
            clean-build-dir=*)            handle_illegal_option_arg "${OPTARG}" ;;
            zfs-kernel-lts)               handle_zfs_kernel_lts ;;
            zfs-kernel-lts=*)             handle_illegal_option_arg "${OPTARG}" ;;
            zfs-kernel-stable)            handle_zfs_kernel_stable ;;
            zfs-kernel-stable=*)          handle_illegal_option_arg "${OPTARG}" ;;
            zfs-kernel-hardened)          handle_zfs_kernel_hardened ;;
            zfs-kernel-hardened=*)        handle_illegal_option_arg "${OPTARG}" ;;
            zfs-kernel-zen)               handle_zfs_kernel_zen ;;
            zfs-kernel-zen=*)             handle_illegal_option_arg "${OPTARG}" ;;
            zfs-kernel-dkms)              handle_zfs_kernel_dkms ;;
            zfs-kernel-dkms=*)            handle_illegal_option_arg "${OPTARG}" ;;
            zfs-kernel-use-git-version)   handle_zfs_kernel_use_git_version ;;
            zfs-kernel-use-git-version=*) handle_illegal_option_arg "${OPTARG}" ;;
            handle-set-build-dir=?*)      handle_set_build_dir "${LONG_OPTARG}" ;;
            handle-set-build-dir*)        handle_missing_option_arg "${OPTARG}" ;;
            extra-packages-from-file=?*)  handle_extra_packages_from_file "${LONG_OPTARG}" ;;
            extra-packages-from-file*)    handle_missing_option_arg "${OPTARG}" ;;
            extra-packages=?*)            handle_extra_packages "${LONG_OPTARG}" ;;
            extra-packages*)              handle_missing_option_arg "${OPTARG}" ;;
            write-iso-to-device=?*)       handle_write_iso_to_device "${LONG_OPTARG}" ;;
            write-iso-to-device*)         handle_missing_option_arg "${OPTARG}" ;;
            '')                           break ;; # non-option arg starting with '-'
            *)                            handle_unknown_option "${OPTARG}" ;;
          esac ;;
      \?) handle_unknown_option "${OPTARG}" ;;
    esac
  done
}

handle_help() {
  print_usage 0
}

handle_clean_build_dir() {
  clean_dir='true'
}

handle_zfs_kernel_lts() {
  if [ "${kernel_pkg}" != '' ]; then
    print_error_msg "multiple zfs kernel packages selected" 1
  else
    kernel_pkg='archzfs-linux-lts'
  fi
}

handle_zfs_kernel_stable() {
  if [ "${kernel_pkg}" != '' ]; then
    print_error_msg "multiple zfs kernel packages selected" 1
  else
    kernel_pkg='archzfs-linux'
  fi
}

handle_zfs_kernel_hardened() {
  if [ "${kernel_pkg}" != '' ]; then
    print_error_msg "multiple zfs kernel packages selected" 1
  else
    kernel_pkg='archzfs-linux-hardened'
  fi
}

handle_zfs_kernel_zen() {
  if [ "${kernel_pkg}" != '' ]; then
    print_error_msg "multiple zfs kernel packages selected" 1
  else
    kernel_pkg='archzfs-linux-zen'
  fi
}

handle_zfs_kernel_dkms() {
  if [ "${kernel_pkg}" != '' ]; then
    print_error_msg "multiple zfs kernel packages selected" 1
  else
    kernel_pkg='archzfs-dkms'
  fi
}

handle_zfs_kernel_use_git_version() {
  use_git_kernel_version='true'
}

handle_set_build_dir() {
  build_dir="${1}"
}

handle_extra_packages() {
  if [ "${extra_packages}" != '' ]; then
    extra_packages="${extra_packages},"
  fi
  extra_packages="${extra_packages}${1}"
}

handle_extra_packages_from_file() {
  while IFS="" read -r pkg || [ -n "$pkg" ]; do
    if [ "${extra_packages}" != '' ]; then
      extra_packages="${extra_packages},"
    fi
    extra_packages="${extra_packages}${pkg}"
  done < "${1}"
}

handle_write_iso_to_device() {
  if [ ! -b "${1}" ]; then
    print_error_msg "${1} not exist or not block device" 1
  fi
  archiso_dev="${1}"
}

handle_unknown_option() {
  err_msg="unknown option \"${1}\""
  print_error_msg "${err_msg}" 1
}

handle_illegal_option_arg() {
  err_msg="illegal argument in \"${1}\""
  print_error_msg "${err_msg}" 1
}

handle_missing_option_arg() {
  err_msg="missing argument for option \"${1}\""
  print_error_msg "${err_msg}" 1
}

print_error_msg() {
  echo 'ERROR:'
  printf "$(basename "${0}"): %s\\n\\n" "${1}"
  print_usage "${2}"
}

check_running_as_root() {
  if [ "$(id -u)" != "0" ]; then
    print_error_msg "must run this script as root" 1
  fi
}

clean_archiso_build_dir() {
  if [ -d "${build_dir}" ]; then
    rm -r "${build_dir}"
  fi
}

check_archiso_installed() {
  if [ ! -d '/usr/share/archiso' ]; then
    print_error_msg "'/usr/share/archiso/' not exist (is archiso installed?)" 1
  fi
}

make_archiso_build_dir() {
  mkdir -p "${build_dir}"
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    err_msg="unable to create archiso build dir '${build_dir}'"
    print_error_msg "${err_msg}" 5
  fi
}

add_archzfs_repo_to_archiso() {
  cat <<- 'EOF' >> "${build_dir}/releng/pacman.conf"
[archzfs]
Server = http://archzfs.com/$repo/x86_64
SigLevel = Optional TrustAll
EOF
}

add_packages_to_archiso() {
  for pkg in $(echo "${extra_packages}" | tr "," " "); do
    printf "%s\\n" "${pkg}" >> "${build_dir}/releng/packages.x86_64"
  done
  if [ "${use_git_kernel_version}" = 'true' ]; then
    kernel_pkg="${kernel_pkg}-git"
  fi
  printf "%s" "${kernel_pkg}" >> "${build_dir}/releng/packages.x86_64"
}

build_archiso() {
  cp -r /usr/share/archiso/configs/releng/ "${build_dir}"
  add_archzfs_repo_to_archiso "$@"
  add_packages_to_archiso "$@"
  "${build_dir}/releng/build.sh" -v
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    print_error_msg "archiso releng/build.sh script failure" 5
  fi
  mv work "${build_dir}/work"
  mv out "${build_dir}/out"
}

write_iso_to_device() {
  if [ ! -d "${build_dir}" ]; then
    err_msg="writing iso from ${build_dir}, but ${build_dir} not exist"
    print_error_msg "${err_msg}" 10
  fi
  dd bs=4M if="${build_dir}/out/archlinux-*" of="${archiso_dev}" status=progress oflag=sync
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    err_msg="writing iso to ${archiso_dev} failure"
    print_error_msg "${err_msg}" 10
  fi
}

main() {
  get_cmd_opts_and_args "$@"
  check_running_as_root "$@"
  if [ "${clean_dir}" = 'true' ]; then
    clean_archiso_build_dir "$@"
  fi
  if [ "${kernel_pkg}" != '' ]; then
    check_archiso_installed "$@"
    make_archiso_build_dir "$@"
    build_archiso "$@"
  fi
  if [ "${archiso_dev}" != '' ]; then
    write_iso_to_device "$@"
  fi
  exit 0
}

main "$@"


#!/bin/sh

################################################################################
# purpose:   build a new archiso with the zfs kernel package on it
# args/opts: see usage (run with -h option)
################################################################################

# global vars:
tmp_build_dir=$(mktemp -u -t archiso_build.XXXXXX) # archiso build dir
tmp_work_dir="${tmp_build_dir}/work"    # archiso working-build dir
iso_out_dir="./out"                     # dir where built archiso will be placed
archiso_dev=''                          # the thumb drive path (e.g. /dev/sdb)
do_build_iso='false'                    # user-selection to build the iso
stable_kernel_pkg=''                    # stable kernel cmd-line selection
extra_packages=''                       # extra packages to install to archiso
user_files=''                           # user files/dirs to add to iso

print_usage() {
  echo 'USAGE:'
  echo "  $(basename "${0}")        -h"
  echo "  sudo  $(basename "${0}")  -b  [-z]  [-p <pkg1,pkg2,...>]  [-P <pkgs_file>]"
  echo '                             [-f <file1,dir1,...>]'
  echo '                             [-w <device>]'
  echo "  sudo  $(basename "${0}")  -w <device>"
  echo 'OPTIONS:'
  echo '  -h, --help'
  echo '      print this help message'
  echo '  -b, --build-iso'
  echo '      build base iso running stock Arch '\''linux'\'' kernel pkg'
  echo '  -z, --enable-zfs-kernel-module'
  echo '      add '\''archzfs-linux'\'' stable kernel mod, enable it at boot'
  echo '  -p <pkg1,pkg2,...>, --extra-packages=<pkg1,pkg2,...>'
  echo '      extra packages to install to iso'
  echo '  -P <pkgs_file>, --extra-packages-file=<pkgs_file>'
  echo '      extra packages to install to iso (from file, one pkg per line)'
  echo '  -f <file1,dir1,...>, --user-files=<file1,dir1,...>'
  echo '      add files and directories to iso (in '\''/root/'\'' dir)'
  echo '  -w <device>, --write-iso-to-device=<device>'
  echo '      write built iso to device (e.g. device /dev/sdb)'
  echo 'EXIT CODES:'
  echo '    0  ok'
  echo '    1  usage, arguments, or options error'
  echo '    5  archiso build error'
  echo '   10  archiso write-to-device error'
  echo '  255  unknown error'
  exit "${1}"
}

get_cmd_opts() {
  while getopts ':hbzp:P:f:w:-:' option; do
    case "${option}" in
      h)  handle_help ;;
      b)  handle_build_iso ;;
      z)  handle_zfs_kernel_stable ;;
      p)  handle_extra_packages "${OPTARG}" ;;
      P)  handle_extra_packages_from_file "${OPTARG}" ;;
      f)  handle_user_files "${OPTARG}" ;;
      w)  handle_write_iso_to_device "${OPTARG}" ;;
      -)  LONG_OPTARG="${OPTARG#*=}"
          case ${OPTARG} in
            help)                        handle_help ;;
            help=*)                      handle_illegal_option_arg "${OPTARG}" ;;
            build-iso)                   handle_build_iso ;;
            build-iso=*)                 handle_illegal_option_arg "${OPTARG}" ;;
            enable-zfs-kernel-module)    handle_zfs_kernel_stable ;;
            enable-zfs-kernel-module=*)  handle_illegal_option_arg "${OPTARG}" ;;
            extra-packages-from-file=?*) handle_extra_packages_from_file "${LONG_OPTARG}" ;;
            extra-packages-from-file*)   handle_missing_option_arg "${OPTARG}" ;;
            extra-packages=?*)           handle_extra_packages "${LONG_OPTARG}" ;;
            extra-packages*)             handle_missing_option_arg "${OPTARG}" ;;
            user-files=?*)               handle_user_files "${LONG_OPTARG}" ;;
            user-files*)                 handle_missing_option_arg "${OPTARG}" ;;
            write-iso-to-device=?*)      handle_write_iso_to_device "${LONG_OPTARG}" ;;
            write-iso-to-device*)        handle_missing_option_arg "${OPTARG}" ;;
            '')                          break ;; # non-option arg starting with '-'
            *)                           handle_unknown_option "${OPTARG}" ;;
          esac ;;
      \?) handle_unknown_option "${OPTARG}" ;;
    esac
  done
}

check_valid_opts() {
  if [ "${do_build_iso}" = 'false' ] && \
     [ "${archiso_dev}" = '' ]; then
    quit_err_msg_with_help "no valid script options selected" 1
  fi
}

handle_help() {
  print_usage 0
}

handle_build_iso() {
  do_build_iso='true'
}

handle_zfs_kernel_stable() {
  stable_kernel_pkg='archzfs-linux'
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

handle_user_files() {
  user_files="${1}"
}

handle_write_iso_to_device() {
  if [ ! -b "${1}" ]; then
    quit_err_msg_with_help "${1} not exist or not block device" 1
  fi
  archiso_dev="${1}"
}

handle_unknown_option() {
  err_msg="unknown option \"${1}\""
  quit_err_msg_with_help "${err_msg}" 1
}

handle_illegal_option_arg() {
  err_msg="illegal argument in \"${1}\""
  quit_err_msg_with_help "${err_msg}" 1
}

handle_missing_option_arg() {
  err_msg="missing argument for option \"${1}\""
  quit_err_msg_with_help "${err_msg}" 1
}

print_err_msg() {
  echo 'ERROR:'
  printf "$(basename "${0}"): %s\\n\\n" "${1}"
}

quit_err_msg() {
  print_err_msg "${1}"
  clean_working_build_dirs "$@"
  exit "${2}"
}

quit_err_msg_with_help() {
  print_err_msg "${1}"
  clean_working_build_dirs "$@"
  print_usage "${2}"
}

check_running_as_root() {
  if [ "$(id -u)" != "0" ]; then
    quit_err_msg_with_help "must run this script as root" 1
  fi
}

check_archiso_installed() {
  if [ ! -d '/usr/share/archiso' ]; then
    quit_err_msg_with_help "'/usr/share/archiso/' not exist (is 'archiso' package installed?)" 1
  fi
}

make_tmp_build_dirs() {
  mkdir "${tmp_build_dir}"
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    err_msg="unable to create working tmp build dir '${tmp_build_dir}'"
    quit_err_msg "${err_msg}" 5
  fi
  mkdir "${tmp_work_dir}"
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    err_msg="unable to create working tmp work dir '${tmp_work_dir}'"
    quit_err_msg "${err_msg}" 5
  fi
  cp -r /usr/share/archiso/configs/releng/ "${tmp_build_dir}"
}

add_archzfs_repo_to_archiso() {
  if [ "${stable_kernel_pkg}" = '' ]; then
    return
  fi
  # archived 'core' repo stable/lts/etc kernel binaries:
  #     https://end.re/2018/05/31/ebp036_archzfs-repo-for-kernels/
  # note: archzfs kernels often depend on these archived binaries
  # note: must be first in repo order, or 'core' kernel binaries will be used
  # shellcheck disable=SC2016
  sed -i '/^\[core\]$/ i\[zfs-linux]\nServer = http://kernels.archzfs.com/$repo\n' "${tmp_build_dir}/releng/pacman.conf"
  # archzfs stable/lts/etc zfs kernel binaries:
  #     https://github.com/archzfs/archzfs/wiki
  # note: archzfs kernels not in other repos, so safe to append to repo order
  # shellcheck disable=SC2016
  sed -i '$ a\\n[archzfs]\nServer = http://archzfs.com/$repo/x86_64\nSigLevel = Optional TrustAll\n' "${tmp_build_dir}/releng/pacman.conf"
}

add_kernel_packages_to_archiso() {
  if [ "${stable_kernel_pkg}" != '' ]; then
    printf "%s\\n" "${stable_kernel_pkg}" >> "${tmp_build_dir}/releng/packages.x86_64"
  fi
}

add_kernel_header_packages_to_archiso() {
  # recommendation: https://wiki.archlinux.org/index.php/ZFS#Embed_the_archzfs_packages_into_an_archiso
  if [ "${stable_kernel_pkg}" != '' ]; then
    printf "linux-headers\\n" >> "${tmp_build_dir}/releng/packages.x86_64"
  fi
}

add_user_packages_to_archiso() {
  for pkg in $(echo "${extra_packages}" | tr "," " "); do
    printf "%s\\n" "${pkg}" >> "${tmp_build_dir}/releng/packages.x86_64"
  done
}

add_user_files_to_archiso() {
  for file_or_dir in $(echo "${user_files}" | tr "," " "); do
    cp -R "${file_or_dir}" "${tmp_build_dir}/releng/airootfs/root/"
  done
}

load_zfs_stable_kernel_on_archiso_boot() {
  # recommended method: https://wiki.archlinux.org/index.php/ZFS#Automatic_Start
  if [ "${stable_kernel_pkg}" != '' ]; then
    mkdir -p "${tmp_build_dir}/releng/airootfs/etc/modules-load.d"
    printf "zfs\\n" > "${tmp_build_dir}/releng/airootfs/etc/modules-load.d/zfs.conf"
  fi
}

run_archiso_build_script() {
  "${tmp_build_dir}/releng/build.sh" -v
  mkarchiso -v -L 'ARCHISO_ZFS' -w "${tmp_work_dir}" "${tmp_build_dir}/releng"
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    quit_err_msg "archiso releng/build.sh script failure" 5
  fi
}

build_archiso() {
  make_tmp_build_dirs "$@"
  add_archzfs_repo_to_archiso "$@"
  add_kernel_packages_to_archiso "$@"
  add_kernel_header_packages_to_archiso "$@"
  add_user_packages_to_archiso "$@"
  add_user_files_to_archiso "$@"
  load_zfs_stable_kernel_on_archiso_boot "$@"
  run_archiso_build_script "$@"
}

write_iso_to_device() {
  if [ ! -d "${iso_out_dir}" ]; then
    err_msg="writing iso from ${iso_out_dir}, but ${iso_out_dir} not exist"
    quit_err_msg_with_help "${err_msg}" 10
  fi
  iso_file=$(ls ./"${iso_out_dir}"/archlinux-*)
  # recommended method: https://wiki.archlinux.org/index.php/USB_flash_installation_media#Using_dd
  dd bs=4M if="${iso_file}" of="${archiso_dev}" status=progress oflag=sync
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    err_msg="writing iso to ${archiso_dev} failure"
    quit_err_msg "${err_msg}" 10
  fi
}

main() {
  get_cmd_opts "$@"
  check_valid_opts "$@"
  check_running_as_root "$@"
  if [ "${do_build_iso}" = 'true' ]; then
    check_archiso_installed "$@"
    build_archiso "$@"
  fi
  if [ "${archiso_dev}" != '' ]; then
    write_iso_to_device "$@"
  fi
  exit 0
}

main "$@"


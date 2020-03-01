#!/bin/sh

################################################################################
# purpose:   build a new archiso with the zfs kernel package on it
# args/opts: see usage (run with -h option)
################################################################################

# global vars:
build_dir='archiso_build'               # build dir for creating archiso
do_clean_dir='false'                    # user-selection to clean build dir
archiso_dev=''                          # the thumb drive path (e.g. /dev/sdb)
do_build_iso='false'                    # user-selection to build the iso
stable_kernel_pkg=''                    # stable kernel cmd-line selection
lts_kernel_pkg=''                       # lts kernel cmd-line selection
extra_packages=''                       # extra packages to install to archiso

print_usage() {
  echo 'USAGE:'
  echo "  $(basename "${0}")        -h"
  echo "  sudo  $(basename "${0}")  -b  [-s]  [-l]  [-d <build_dir>]"
  echo '                             [-p <pkg1,pkg2,...>]  [-f <pkgs_file>]'
  echo '                             [-w <device>]'
  echo "  sudo  $(basename "${0}")  [-d <build_dir>]  -w <device>"
  echo 'OPTIONS:'
  echo '  -h, --help'
  echo '      print this help message'
  echo '  -c --clean-build-dir'
  echo '      remove archiso build dir before performing any operations'
  echo '  -b, --build-iso'
  echo '      build base iso running stock Arch '\''linux'\'' kernel pkg'
  echo '  -s, --add-and-enable-stable-zfs-kernel'
  echo '      add '\''archzfs-linux'\'' kernel pkg and enable it at boot'
  echo '  -l, --add-lts-zfs-kernel'
  echo '      add '\''archzfs-linux-lts'\'' kernel pkg'
  echo '  -d <build_dir>, --set-build-dir=<build_dir>'
  echo '      set archiso build dir (default is '\''archiso_build'\'')'
  echo '  -p <pkg1,pkg2,...>, --extra-packages=<pkg1,pkg2,...>'
  echo '      extra packages to install to iso'
  echo '  -f <pkgs_file>, --extra-packages-file=<pkgs_file>'
  echo '      extra packages to install to iso (from file, one pkg per line)'
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

get_cmd_opts_and_args() {
  while getopts ':hcbsld:f:p:w:-:' option; do
    case "${option}" in
      h)  handle_help ;;
      c)  handle_clean_build_dir ;;
      b)  handle_build_iso ;;
      s)  handle_zfs_kernel_stable ;;
      l)  handle_zfs_kernel_lts ;;
      d)  handle_set_build_dir "${OPTARG}" ;;
      f)  handle_extra_packages_from_file "${OPTARG}" ;;
      p)  handle_extra_packages "${OPTARG}" ;;
      w)  handle_write_iso_to_device "${OPTARG}" ;;
      -)  LONG_OPTARG="${OPTARG#*=}"
          case ${OPTARG} in
            help)                        handle_help ;;
            help=*)                      handle_illegal_option_arg "${OPTARG}" ;;
            clean-build-dir)             handle_clean_build_dir ;;
            clean-build-dir=*)           handle_illegal_option_arg "${OPTARG}" ;;
            build-iso)                   handle_build_iso ;;
            build-iso=*)                 handle_illegal_option_arg "${OPTARG}" ;;
            add-and-enable-stable-zfs-kernel)   handle_zfs_kernel_stable ;;
            add-and-enable-stable-zfs-kernel=*) handle_illegal_option_arg "${OPTARG}" ;;
            add-lts-zfs-kernel)          handle_zfs_kernel_lts ;;
            add-lts-zfs-kernel=*)        handle_illegal_option_arg "${OPTARG}" ;;
            handle-set-build-dir=?*)     handle_set_build_dir "${LONG_OPTARG}" ;;
            handle-set-build-dir*)       handle_missing_option_arg "${OPTARG}" ;;
            extra-packages-from-file=?*) handle_extra_packages_from_file "${LONG_OPTARG}" ;;
            extra-packages-from-file*)   handle_missing_option_arg "${OPTARG}" ;;
            extra-packages=?*)           handle_extra_packages "${LONG_OPTARG}" ;;
            extra-packages*)             handle_missing_option_arg "${OPTARG}" ;;
            write-iso-to-device=?*)      handle_write_iso_to_device "${LONG_OPTARG}" ;;
            write-iso-to-device*)        handle_missing_option_arg "${OPTARG}" ;;
            '')                          break ;; # non-option arg starting with '-'
            *)                           handle_unknown_option "${OPTARG}" ;;
          esac ;;
      \?) handle_unknown_option "${OPTARG}" ;;
    esac
  done
}

handle_help() {
  print_usage 0
}

handle_clean_build_dir() {
  do_clean_dir='true'
}

handle_build_iso() {
  do_build_iso='true'
}

handle_zfs_kernel_stable() {
  stable_kernel_pkg='archzfs-linux'
}

handle_zfs_kernel_lts() {
  lts_kernel_pkg='archzfs-linux-lts'
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

clean_archiso_build_dir() {
  if [ -d "${build_dir}" ]; then
    rm -r "${build_dir}"
  fi
}

check_archiso_installed() {
  if [ ! -d '/usr/share/archiso' ]; then
    quit_err_msg_with_help "'/usr/share/archiso/' not exist (is archiso installed?)" 1
  fi
}

make_archiso_build_dir() {
  mkdir -p "${build_dir}"
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    err_msg="unable to create archiso build dir '${build_dir}'"
    quit_err_msg "${err_msg}" 5
  fi
  cp -r /usr/share/archiso/configs/releng/ "${build_dir}"
}

add_archzfs_repo_to_archiso() {
  if [ "${stable_kernel_pkg}" = '' ] && [ "${lts_kernel_pkg}" = '' ]; then
    return
  fi
  # archived 'core' repo stable/lts/etc kernel binaries:
  #     https://end.re/2018/05/31/ebp036_archzfs-repo-for-kernels/
  # note: archzfs kernels often depend on these archived binaries
  # note: must be first in repo order, or 'core' kernel binaries will be used
  # shellcheck disable=SC2016
  sed -i '/^\[core\]$/ i\[archzfs-kernels]\nServer = http://end.re/$repo\n' "${build_dir}/releng/pacman.conf"
  # archzfs stable/lts/etc zfs kernel binaries:
  #     https://github.com/archzfs/archzfs/wiki
  # note: archzfs kernels not in other repos, so safe to append to repo order
  # shellcheck disable=SC2016
  sed -i '$ a\\n[archzfs]\nServer = http://archzfs.com/$repo/x86_64\nSigLevel = Optional TrustAll\n' "${build_dir}/releng/pacman.conf"
}

add_kernel_packages_to_archiso() {
  if [ "${stable_kernel_pkg}" != '' ]; then
    printf "%s\\n" "${stable_kernel_pkg}" >> "${build_dir}/releng/packages.x86_64"
  fi
  if [ "${lts_kernel_pkg}" != '' ]; then
    printf "%s\\n" "${lts_kernel_pkg}" >> "${build_dir}/releng/packages.x86_64"
  fi
}

add_kernel_header_packages_to_archiso() {
  # recommendation: https://wiki.archlinux.org/index.php/ZFS#Embed_the_archzfs_packages_into_an_archiso
  if [ "${stable_kernel_pkg}" != '' ]; then
    printf "linux-headers\\n" >> "${build_dir}/releng/packages.x86_64"
  fi
  if [ "${lts_kernel_pkg}" != '' ]; then
    printf "linux-lts-headers\\n" >> "${build_dir}/releng/packages.x86_64"
  fi
}

add_user_packages_to_archiso() {
  for pkg in $(echo "${extra_packages}" | tr "," " "); do
    printf "%s\\n" "${pkg}" >> "${build_dir}/releng/packages.x86_64"
  done
}

load_zfs_stable_kernel_on_archiso_boot() {
  # recommended method: https://wiki.archlinux.org/index.php/ZFS#Automatic_Start
  if [ "${stable_kernel_pkg}" != '' ]; then
    mkdir -p "${build_dir}/releng/airootfs/etc/modules-load.d"
    printf "zfs\\n" > "${build_dir}/releng/airootfs/etc/modules-load.d/zfs.conf"
  fi
}

run_archiso_build_script() {
  "${build_dir}/releng/build.sh" -v
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    quit_err_msg "archiso releng/build.sh script failure" 5
  fi
}

clean_working_build_dirs() {
  if [ -d "${build_dir}" ]; then
    [ -d work ] && mv work "${build_dir}/work"
    [ -d out ] && mv out "${build_dir}/out"
  else
    [ -d work ] && rm -r work
    [ -d out ] && rm -r out
  fi
}

build_archiso() {
  make_archiso_build_dir "$@"
  add_archzfs_repo_to_archiso "$@"
  add_kernel_packages_to_archiso "$@"
  add_kernel_header_packages_to_archiso "$@"
  add_user_packages_to_archiso "$@"
  load_zfs_stable_kernel_on_archiso_boot "$@"
  run_archiso_build_script "$@"
  clean_working_build_dirs "$@"
}

write_iso_to_device() {
  if [ ! -d "${build_dir}" ]; then
    err_msg="writing iso from ${build_dir}, but ${build_dir} not exist"
    quit_err_msg_with_help "${err_msg}" 10
  fi
  iso_file=$(ls ./"${build_dir}"/out/archlinux-*)
  # recommended method: https://wiki.archlinux.org/index.php/USB_flash_installation_media#Using_dd
  dd bs=4M if="${iso_file}" of="${archiso_dev}" status=progress oflag=sync
  exit_code="${?}"
  if [ "${exit_code}" != 0 ]; then
    err_msg="writing iso to ${archiso_dev} failure"
    quit_err_msg "${err_msg}" 10
  fi
}

main() {
  get_cmd_opts_and_args "$@"
  check_running_as_root "$@"
  if [ "${do_clean_dir}" = 'true' ]; then
    clean_archiso_build_dir "$@"
  fi
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


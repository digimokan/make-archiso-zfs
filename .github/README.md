# make-archiso-zfs

Shell script to build Arch Linux iso that runs zfs kernel.

[![License](https://img.shields.io/badge/license-MIT-blue.svg?label=license)](LICENSE.txt "Project License")

## Table Of Contents

* [Motivation](#motivation)
* [Features](#features)
* [Requirements](#requirements)
* [Quick Start](#quick-start)
* [Full Usage / Options](#full-usage--options)
* [Examples](#examples)
* [Source And Build Files](#source-and-build-files)
* [Contributing](#contributing)

## Motivation

Automate the steps in [Archwiki: ZFS]
(https://wiki.archlinux.org/index.php/ZFS#Embed_the_archzfs_packages_into_an_archiso)
required to build an Arch Linux iso.

## Features

* Built iso runs the stable zfs kernel (`archzfs-linux`), loaded at iso boot.
* Option to install unloaded lts zfs kernel (`archzfs-linux-lts`).
* Option to install extra user-specified packages, from cmd line or input file.
* Option to write the built iso to device (i.e. /dev/sdx USB drive).
* Simple shell-agnostic script, [`shellcheck`](https://github.com/koalaman/shellcheck)
  error and warning free.
* Script help menu and clear examples.

## Requirements

* Arch Linux
* [archiso](https://www.archlinux.org/packages/?name=archiso) package

## Quick Start

1. Clone project into a local project directory:

   ```shell
   $ git clone https://github.com/digimokan/make-archiso-zfs.git
   ```

2. Change to the local project directory:

   ```shell
   $ cd make-archiso-zfs
   ```

3. Build an archiso and write it to a USB drive:

   ```shell
   $ ./make_archiso_zfs.sh --build-with-stable-zfs-kernel --write-iso-to-device=/dev/sdc
   ```

## Full Usage / Options

```
USAGE:
  make_archiso_zfs.sh  -h
  sudo  make_archiso_zfs.sh  -b  [-l]  [-d <build_dir>]
                             [-p <pkg1,pkg2,...>]  [-f <pkgs_file>]
                             [-w <device>]
  sudo  make_archiso_zfs.sh  [-d <build_dir>]  -w <device>
OPTIONS:
  -h, --help
      print this help message
  -c --clean-build-dir
      remove archiso build dir before performing any operations
  -b, --build-with-stable-zfs-kernel
      build base iso running archzfs-linux kernel package
  -l, --add-lts-zfs-kernel
      add archzfs-linux-lts kernel package to iso
  -d <build_dir>, --set-build-dir=<build_dir>
      set archiso build dir (default is 'archiso_build')
  -p <pkg1,pkg2,...>, --extra-packages=<pkg1,pkg2,...>
      extra packages to install to iso
  -f <pkgs_file>, --extra-packages-file=<pkgs_file>
      extra packages to install to iso (from file, one pkg per line)
  -w <device>, --write-iso-to-device=<device>
      write built iso to device (e.g. device /dev/sdb)
EXIT CODES:
    0  ok
    1  usage, arguments, or options error
    5  archiso build error
   10  archiso write-to-device error
  255  unknown error
```

## Examples

* Build archiso running stable zfs kernel, do not write output to device:

   ```shell
   $ ./make-archiso-zfs.sh -s
   ```

* Build archiso running stable zfs kernel, and add lts zfs kernel package:

   ```shell
   $ ./make-archiso-zfs.sh -sl
   ```

* Build archiso running stable zfs kernel, and add lts zfs kernel package:

   ```shell
   $ ./make-archiso-zfs.sh -sl
   ```

## Source And Build Files

```
├─┬ make-archiso-zfs/
│ │
│ ├─┬ archiso_build/               # build directory
│ │ ├── out/                       # final build output: the iso file
│ │ ├── releng/                    # config directory used in build prep
│ │ └── work/                      # working directory used while building
│ │
│ ├── make-archiso-zfs.sh          # the build script
│ │
```

## Contributing

* Feel free to report a bug or propose a feature by opening a new
  [Issue](https://github.com/digimokan/make-archiso-zfs/issues).
* Follow the project's [Contributing](CONTRIBUTING.md) guidelines.
* Respect the project's [Code Of Conduct](CODE_OF_CONDUCT.md).

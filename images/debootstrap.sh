#!/usr/bin/env bash

# Prints an error message in bold red then exits
function die() {
    printf "\n\033[01;31m%s\033[0m\n" "${1}"
    exit "${2:-33}"
}

# Checks if command is available
function is_available() {
    command -v "${1}" &>/dev/null || die "${1} needs to be installed!"
}

# Do some initial checks for environment and configuration
function initial_setup() {
    [[ ${EUID} -eq 0 ]] || die "Script should be run as root!"
    [[ ${#} -eq 0 ]] || die "Architecture needs to be provided as an argument to the script!"
    is_available debootstrap
    is_available qemu-img
}

function get_architecture() {
    while ((${#})); do
        case ${1} in
            x86_64)
                DEB_ARCH=amd64
                OUR_ARCH=${1}
                ;;
            *) die "${1} is not supported by this script!" ;;
        esac
        shift
    done
}

function create_img() {
    WORK_DIR=$(mktemp -d -p "$(readlink -f "$(dirname "${0}")")")
    ORIG_USER=$(logname)

    MOUNT_DIR=${WORK_DIR}/rootfs
    IMG=${WORK_DIR}/debian.img

    qemu-img create "${IMG}" 5g
    mkfs.ext2 "${IMG}"

    mkdir -p "${MOUNT_DIR}"
    mount -o loop "${IMG}" "${MOUNT_DIR}"
    debootstrap --arch "${DEB_ARCH}" buster "${MOUNT_DIR}"
    umount "${MOUNT_DIR}"

    chown -R "${ORIG_USER}:${ORIG_USER}" "${IMG}"
    mv -v "${IMG}" "${WORK_DIR%/*}/${OUR_ARCH}"
    rm -rf "${WORK_DIR}"
}

initial_setup
get_architecture "${@}"
create_img

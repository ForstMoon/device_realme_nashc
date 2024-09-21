#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=nashc
VENDOR=realme

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

export TARGET_ENABLE_CHECKELF=true

# If XML files don't have comments before the XML header, use this flag
# Can still be used with broken XML files by using blob_fixup
export TARGET_DISABLE_XML_FIXING=true

export PATCHELF_VERSION=0_17_2

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_FIRMWARE=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-firmware)
            ONLY_FIRMWARE=true
            ;;
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        system_ext/priv-app/ImsService/ImsService.apk)
            [ "$2" = "" ] && return 0
            apktool_patch "${2}" "${MY_DIR}/blob-patches/ImsService.patch"
            ;;
        system_ext/lib64/libsink.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "libshim_sink.so" "${2}"
            ;;
        system_ext/lib64/libsource.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "libui_shim.so" "${2}"
            ;;
        odm/bin/hw/vendor.oplus.hardware.charger@1.0-service|\
        odm/lib64/libosenseaidlhalclient.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "vendor.oplus.hardware.osense.client-V1-ndk_platform.so" "vendor.oplus.hardware.osense.client-V1-ndk.so" "${2}"
            ;;
        vendor/bin/hw/android.hardware.gnss-service.mediatek|\
        vendor/lib64/hw/android.hardware.gnss-impl-mediatek.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.hardware.gnss-V1-ndk_platform.so" "android.hardware.gnss-V1-ndk.so" "${2}"
            ;;
        vendor/bin/hw/android.hardware.media.c2@1.2-mediatek-64b)
            [ "$2" = "" ] && return 0
            grep -q "libstagefright_foundation-v33.so" "${2}" || "${PATCHELF}" --add-needed "libstagefright_foundation-v33.so" "${2}"
            "${PATCHELF}" --replace-needed "libavservices_minijail_vendor.so" "libavservices_minijail.so" "${2}"
            ;;
       vendor/etc/init/android.hardware.neuralnetworks@1.3-service-mtk-neuron.rc)
            [ "$2" = "" ] && return 0
            sed -i 's/start/enable/' "${2}"
            ;;
        vendor/etc/libnfc-nci.conf)
            [ "$2" = "" ] && return 0
            sed -i "s/NFC_DEBUG_ENABLED=0x01/NFC_DEBUG_ENABLED=0x00/" "${2}"
            ;;
        vendor/etc/libnfc-nxp.conf)
            [ "$2" = "" ] && return 0
            sed -i "/NXPLOG_\w\+_LOGLEVEL/ s/0x03/0x02/" "${2}"
            sed -i "s/NFC_DEBUG_ENABLED=0x01/NFC_DEBUG_ENABLED=0x00/" "${2}"
            ;;
        vendor/lib64/hw/android.hardware.camera.provider@2.6-impl-mediatek.so)
            [ "$2" = "" ] && return 0
            grep -q "libcamera_metadata_shim.so" "${2}" || "${PATCHELF}" --add-needed "libcamera_metadata_shim.so" "${2}"
            ;&
        vendor/lib64/libmtkcam_stdutils.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
            ;;
        vendor/bin/mnld|\
        vendor/lib64/libaalservice.so|\
        vendor/lib64/libcam.utils.sensorprovider.so|\
        vendor/lib64/liboplus_mtkcam_lightsensorprovider.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libsensorndkbridge.so" "android.hardware.sensors@1.0-convert-shared.so" "${2}"
            ;;
        vendor/lib64/hw/audio.primary.mt6785.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libalsautils.so" "libalsautils-v31.so" "${2}"
            ;;
        vendor/lib64/libmnl.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "libcutils.so" "${2}"
            ;;
        vendor/lib64/libSQLiteModule_VER_ALL.so|\
        vendor/lib64/lib3a.flash.so|\
        vendor/lib64/lib3a.ae.stat.so|\
        vendor/lib64/lib3a.sensors.color.so|\
        vendor/lib64/lib3a.sensors.flicker.so|\
        vendor/lib64/libaaa_ltm.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "liblog.so" "${2}"
            ;;
        vendor/lib64/hw/vendor.mediatek.hardware.pq@2.15-impl.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
            "${PATCHELF}" --replace-needed "libsensorndkbridge.so" "android.hardware.sensors@1.0-convert-shared.so" "${2}"
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

function lib_to_package_fixup_vendor_variants() {
    if [ "$2" != "vendor" ]; then
        return 1
    fi

    case "$1" in
        vendor.mediatek.hardware.videotelephony@1.0)
            echo "${1}_vendor"
            ;;
        *)
            return 1
            ;;
    esac
}

function lib_to_package_fixup() {
    lib_to_package_fixup_clang_rt_ubsan_standalone "$1" ||
        lib_to_package_fixup_proto_3_9_1 "$1" ||
        lib_to_package_fixup_vendor_variants "$@"
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

if [ -z "${ONLY_FIRMWARE}" ]; then
    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${SECTION}" ]; then
    extract_firmware "${MY_DIR}/proprietary-firmware.txt" "${SRC}"
fi

"${MY_DIR}/setup-makefiles.sh"

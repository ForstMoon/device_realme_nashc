#
# SPDX-FileCopyrightText: 2022-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

import common

BLOCK_DEV_PATH = "/dev/block/by-name/"

FIRMWARE_IMAGES = {
  "audio_dsp.img": ["audio_dsp"],
  "cam_vpu1.img": ["cam_vpu1"],
  "cam_vpu2.img": ["cam_vpu2"],
  "cam_vpu3.img": ["cam_vpu3"],
  "gz.img": ["gz1", "gz2"],
  "lk.img": ["lk", "lk2"],
  "logo.img": ["logo"],
  "md1img.img": ["md1img"],
  "preloader.img": ["preloader", "preloader_backup"],
  "scp.img": ["scp1", "scp2"],
  "spmfw.img": ["spmfw"],
  "sspm.img": ["sspm_1", "sspm_2"],
  "tee.img": ["tee1", "tee2"]
}

ADDITIONAL_IMAGES = {
  "dtbo.img": "dtbo",
  "vbmeta.img": "vbmeta",
  "vbmeta_system.img": "vbmeta_system",
  "vbmeta_vendor.img": "vbmeta_vendor"
}

def FullOTA_InstallBegin(info):
  OTA_InstallBegin(info)

def IncrementalOTA_InstallBegin(info):
  OTA_InstallBegin(info)

def FullOTA_InstallEnd(info):
  OTA_InstallEnd(info)

def IncrementalOTA_InstallEnd(info):
  OTA_InstallEnd(info)

def AddImage(info, dir, name):
  data = info.input_zip.read(dir + name)
  common.ZipWriteStr(info.output_zip, name, data)

def FlashImage(info, name, dest):
  info.script.Print("Patching {} image unconditionally...".format(dest.split('/')[-1]))
  info.script.AppendExtra('package_extract_file("%s", "%s");' % (name, dest))

def OTA_InstallBegin(info):
  info.script.Print("Updating firmware images...")
  for image, parts in FIRMWARE_IMAGES.items():
    AddImage(info, "RADIO/", image)
    for part in parts:
      FlashImage(info, image, BLOCK_DEV_PATH + part)

def OTA_InstallEnd(info):
  for image, part in ADDITIONAL_IMAGES.items():
    AddImage(info, "IMAGES/", image)
    FlashImage(info, image, BLOCK_DEV_PATH + part)

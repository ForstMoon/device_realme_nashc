#
# SPDX-FileCopyrightText: 2022-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

import common

FIRMWARE_IMAGES = {
  "audio_dsp.img": "audio_dsp",
  "cam_vpu1.img": "cam_vpu1",
  "cam_vpu2.img": "cam_vpu2",
  "cam_vpu3.img": "cam_vpu3",
  "gz.img": "gz",
  "lk.img": "lk",
  "md1img.img": "md1img",
  "preloader.img": "preloader",
  "scp.img": "scp",
  "spmfw.img": "spmfw",
  "sspm.img": "sspm",
  "tee.img": "tee"
}

def FullOTA_InstallBegin(info):
  OTA_InstallBegin(info)

def IncrementalOTA_InstallBegin(info):
  OTA_InstallBegin(info)

def FullOTA_InstallEnd(info):
  OTA_InstallEnd(info)

def IncrementalOTA_InstallEnd(info):
  OTA_InstallEnd(info)

def AddImage(info, dir, basename, dest):
  name = basename
  data = info.input_zip.read(dir + basename)
  common.ZipWriteStr(info.output_zip, name, data)
  FlashImage(info, name, dest)

def FlashImage(info, name, dest):
  info.script.Print("Patching {} image unconditionally...".format(dest.split('/')[-1]))
  info.script.AppendExtra('package_extract_file("%s", "%s");' % (name, dest))

def OTA_InstallBegin(info):
  info.script.Print("Updating firmware images...")
  for name, part in FIRMWARE_IMAGES.items():
    AddImage(info, "RADIO/", name, "/dev/block/by-name/" + part)

  FlashImage(info, "preloader.img", "/dev/block/by-name/preloader_backup")

def OTA_InstallEnd(info):
  AddImage(info, "IMAGES/", "dtbo.img", "/dev/block/by-name/dtbo")
  AddImage(info, "IMAGES/", "vbmeta.img", "/dev/block/by-name/vbmeta")
  AddImage(info, "IMAGES/", "vbmeta_system.img", "/dev/block/by-name/vbmeta_system")
  AddImage(info, "IMAGES/", "vbmeta_vendor.img", "/dev/block/by-name/vbmeta_vendor")

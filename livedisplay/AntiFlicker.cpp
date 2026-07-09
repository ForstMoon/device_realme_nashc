/*
 * Copyright (C) 2022 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "AntiFlicker.h"

#include <android-base/file.h>
#include <android-base/strings.h>

using ::android::base::ReadFileToString;
using ::android::base::Trim;
using ::android::base::WriteStringToFile;

namespace {
constexpr const char* kDcDimmingPath = "/sys/kernel/oplus_display/dimlayer_bl_en";
}  // anonymous namespace

namespace aidl {
namespace vendor {
namespace lineage {
namespace livedisplay {
namespace implementation {

ndk::ScopedAStatus AntiFlicker::getEnabled(bool* _aidl_return) {
    std::string tmp;
    int32_t contents = 0;

    if (ReadFileToString(kDcDimmingPath, &tmp)) {
        contents = std::stoi(Trim(tmp));
    }

    *_aidl_return = contents > 0;
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus AntiFlicker::setEnabled(bool enabled) {
    if (!WriteStringToFile(std::to_string(enabled), kDcDimmingPath, true)) {
        return ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_STATE);
    }
    return ndk::ScopedAStatus::ok();
}

}  // namespace implementation
}  // namespace livedisplay
}  // namespace lineage
}  // namespace vendor
}  // namespace aidl

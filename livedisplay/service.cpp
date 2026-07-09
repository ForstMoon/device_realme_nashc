/*
 * Copyright (C) 2019 The LineageOS Project
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

#include <android-base/logging.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>

#include "AntiFlicker.h"
#include "SunlightEnhancement.h"

using aidl::vendor::lineage::livedisplay::implementation::AntiFlicker;
using aidl::vendor::lineage::livedisplay::implementation::SunlightEnhancement;

int main() {
    ABinderProcess_setThreadPoolMaxThreadCount(0);

    std::shared_ptr<AntiFlicker> af = ndk::SharedRefBase::make<AntiFlicker>();
    std::shared_ptr<SunlightEnhancement> se = ndk::SharedRefBase::make<SunlightEnhancement>();

    const std::string afInstance = std::string() + AntiFlicker::descriptor + "/default";
    if (AServiceManager_addService(af->asBinder().get(), afInstance.c_str()) != STATUS_OK) {
        LOG(ERROR) << "Cannot register anti flicker AIDL service.";
        return 1;
    }

    const std::string seInstance = std::string() + SunlightEnhancement::descriptor + "/default";
    if (AServiceManager_addService(se->asBinder().get(), seInstance.c_str()) != STATUS_OK) {
        LOG(ERROR) << "Cannot register sunlight enhancement AIDL service.";
        return 1;
    }

    LOG(INFO) << "LiveDisplay AIDL HAL service is ready.";
    ABinderProcess_joinThreadPool();

    LOG(ERROR) << "LiveDisplay AIDL HAL service failed to join thread pool.";
    return EXIT_FAILURE;
}

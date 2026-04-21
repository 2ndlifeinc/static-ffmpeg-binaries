#!/bin/bash

# Copyright 2026 2ndlifeinc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0

set -e
set -x

tag=$(repo-src/get-version.sh aom)
git clone --depth 1 https://aomedia.googlesource.com/aom -b "$tag"

mkdir aom-build
cd aom-build

cmake ../aom \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DBUILD_SHARED_LIBS=OFF \
  -DENABLE_TESTS=OFF \
  -DENABLE_EXAMPLES=OFF \
  -DENABLE_DOCS=OFF \
  -DCONFIG_RUNTIME_CPU_DETECT=1

make
$SUDO make install

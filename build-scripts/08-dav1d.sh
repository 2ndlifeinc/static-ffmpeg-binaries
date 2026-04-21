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

tag=$(repo-src/get-version.sh dav1d)
git clone --depth 1 https://code.videolan.org/videolan/dav1d.git -b "$tag"

mkdir dav1d-build
cd dav1d-build

meson setup ../dav1d \
  --prefix=/usr/local \
  --buildtype=release \
  --default-library=static \
  -Denable_tools=false \
  -Denable_tests=false \
  -Denable_examples=false

ninja
$SUDO ninja install

#!/bin/bash

# This code is part of Qiskit.
#
# (C) Copyright IBM 2018, 2019.
#
# This code is licensed under the Apache License, Version 2.0. You may
# obtain a copy of this license in the LICENSE.txt file in the root directory
# of this source tree or at http://www.apache.org/licenses/LICENSE-2.0.
#
# Any modifications or derivative works of this code must retain this
# copyright notice, and modified files need to carry a notice indicating
# that they have been altered from the originals.

# Script for pushing the documentation to the qiskit.org repository.

# Non-travis variables used by this script.
SOURCE_REPOSITORY="https://github.com/Qiskit/qiskit.git"
TARGET_DOC_DIR="documentation/locale/"
SOURCE_DOC_DIR="docs/_build/html/locale"
SOURCE_DIR=`pwd`

curl https://downloads.rclone.org/rclone-current-linux-amd64.deb -o rclone.deb
sudo apt-get install -y ./rclone.deb

RCLONE_CONFIG_PATH=$(rclone config file | tail -1)

set -e

CURRENT_TAG=`git describe --abbrev=0`
IFS=. read -ra VERSION <<< "$CURRENT_TAG"
STABLE_VERSION="${VERSION[0]}.${VERSION[1]}"

# Clone the sources files and po files to $SOURCE_DIR/docs_source
git clone --depth=1 $SOURCE_REPOSITORY docs_source
rclone sync -v --exclude='locale/**' docs_source/docs docs

pushd $SOURCE_DIR/docs

# Make translated document

sphinx-build -b html -j auto -D content_prefix=documentation/stable/"$STABLE_VERSION" -D language=$TRANSLATION_LANG . _build/html/locale/$TRANSLATION_LANG

popd

openssl aes-256-cbc -K $encrypted_rclone_key -iv $encrypted_rclone_iv -in tools/rclone.conf.enc -out $RCLONE_CONFIG_PATH -d

echo "Pushing built docs to website"
rclone sync --progress ./docs/_build/html/stable/"$STABLE_VERSION"/locale/$TRANSLATION_LANG IBMCOS:qiskit-org-web-resources/documentation/stable/"$STABLE_VERSION"/locale/$TRANSLATION_LANG

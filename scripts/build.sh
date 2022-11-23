#!/bin/bash
set -e

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJECT_PATH="$(cd "${SCRIPTPATH}/.." ; pwd)"

PODSPEC_FILE="$(ls "${PROJECT_PATH}" | grep ".*\.podspec")"
TARGET_NAME="$(echo "${PODSPEC_FILE}" | cut -f 1 -d '.')"

echo "Install ruby dependencies"
bundle

echo "Cleanning Podfile structure"
(cd "${PROJECT_PATH}/${TARGET_NAME}" ; bundle exec pod deintegrate)
[[ -f "${PROJECT_PATH}/${TARGET_NAME}/Podfile" ]] && rm "${PROJECT_PATH}/${TARGET_NAME}/Podfile"
[[ -f "${PROJECT_PATH}/${TARGET_NAME}/Podfile.lock" ]] && rm "${PROJECT_PATH}/${TARGET_NAME}/Podfile.lock"
[[ -d "${PROJECT_PATH}/${TARGET_NAME}/${TARGET_NAME}.xcworkspace" ]] && rm -r "${PROJECT_PATH}/${TARGET_NAME}/${TARGET_NAME}.xcworkspace"

echo "Align project files"
bundle exec ruby "${SCRIPTPATH}/align_plugin_files.rb" "${TARGET_NAME}"

echo "Create support Podfile"
bundle exec ruby "${SCRIPTPATH}/recreate_podfile.rb" "${TARGET_NAME}" "${PROJECT_PATH}/${PODSPEC_FILE}" "${PROJECT_PATH}/${TARGET_NAME}" "${SCRIPTPATH}/Podfile.erb"

echo "Run pod install"
(cd "${PROJECT_PATH}/${TARGET_NAME}" ; bundle exec pod install --repo-update)

echo "Build XCFramework"
"${SCRIPTPATH}/build_framework.sh" "--workspace" "${PROJECT_PATH}/${TARGET_NAME}/${TARGET_NAME}.xcworkspace" --target "${TARGET_NAME}" --ci

echo "Cleanning Podfile structure"
(cd "${PROJECT_PATH}/${TARGET_NAME}" ; bundle exec pod deintegrate)
[[ -f "${PROJECT_PATH}/${TARGET_NAME}/Podfile" ]] && rm "${PROJECT_PATH}/${TARGET_NAME}/Podfile"
[[ -f "${PROJECT_PATH}/${TARGET_NAME}/Podfile.lock" ]] && rm "${PROJECT_PATH}/${TARGET_NAME}/Podfile.lock"
[[ -d "${PROJECT_PATH}/${TARGET_NAME}/${TARGET_NAME}.xcworkspace" ]] && rm -r "${PROJECT_PATH}/${TARGET_NAME}/${TARGET_NAME}.xcworkspace"

echo "Undoing File structure changes"
git checkout -- "${TARGET_NAME}/${TARGET_NAME}.xcodeproj/project.pbxproj"
#!/bin/bash
set -e

WORKING_DIR=$(pwd)
FRAMEWORK_FOLDER_NAME="Frameworks"

create_xcframework() {
  FRAMEWORK_NAME=$1
  FRAMEWORK_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/${FRAMEWORK_NAME}.xcframework"
  if [ "${FRAMEWORK_NAME}" = "CleverPushExtension" ]; then
    BUILD_SCHEME="CleverPushExtension"
  else
    BUILD_SCHEME="${FRAMEWORK_NAME}Framework"
  fi

  SIMULATOR_ARCHIVE_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/${FRAMEWORK_NAME}-Simulator.xcarchive"
  IOS_DEVICE_ARCHIVE_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/${FRAMEWORK_NAME}-iOS.xcarchive"
  CATALYST_ARCHIVE_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/${FRAMEWORK_NAME}-Catalyst.xcarchive"

  DSYMS_FOLDER="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/${FRAMEWORK_NAME}.dSYMs"
  SIMULATOR_DSYM="${SIMULATOR_ARCHIVE_PATH}/dSYMs/${FRAMEWORK_NAME}.framework.dSYM"
  IOS_DEVICE_DSYM="${IOS_DEVICE_ARCHIVE_PATH}/dSYMs/${FRAMEWORK_NAME}.framework.dSYM"
  CATALYST_DSYM="${CATALYST_ARCHIVE_PATH}/dSYMs/${FRAMEWORK_NAME}.framework.dSYM"

  rm -rf "${FRAMEWORK_PATH}"
  rm -rf "${DSYMS_FOLDER}"

  xcodebuild archive ONLY_ACTIVE_ARCH=NO -scheme ${BUILD_SCHEME} -destination="generic/platform=iOS Simulator" -archivePath "${SIMULATOR_ARCHIVE_PATH}" -sdk iphonesimulator SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

  xcodebuild archive -scheme ${BUILD_SCHEME} -destination="generic/platform=iOS" -archivePath "${IOS_DEVICE_ARCHIVE_PATH}" -sdk iphoneos SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

  CATALYST_FRAMEWORK_PATH="${CATALYST_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
  if [ "${FRAMEWORK_NAME}" = "CleverPushExtension" ]; then
    xcodebuild -create-xcframework -framework ${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -framework ${IOS_DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -output "${FRAMEWORK_PATH}"
  else
    xcodebuild archive ONLY_ACTIVE_ARCH=NO -scheme ${BUILD_SCHEME} -destination='generic/platform=macOS,variant=Mac Catalyst' -archivePath "${CATALYST_ARCHIVE_PATH}" -sdk macosx SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES SUPPORTS_MACCATALYST=YES IPHONEOS_DEPLOYMENT_TARGET=16.0
    xcodebuild -create-xcframework -framework ${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -framework ${IOS_DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -framework ${CATALYST_FRAMEWORK_PATH} -output "${FRAMEWORK_PATH}"
  fi

  mkdir -p "${DSYMS_FOLDER}"

  if [ -d "${SIMULATOR_DSYM}" ]; then
    mkdir -p "${DSYMS_FOLDER}/ios-arm64_x86_64-simulator"
    cp -R "${SIMULATOR_DSYM}" "${DSYMS_FOLDER}/ios-arm64_x86_64-simulator/"
  fi

  if [ -d "${IOS_DEVICE_DSYM}" ]; then
    mkdir -p "${DSYMS_FOLDER}/ios-arm64"
    cp -R "${IOS_DEVICE_DSYM}" "${DSYMS_FOLDER}/ios-arm64/"
  fi

  if [ "${FRAMEWORK_NAME}" != "CleverPushExtension" ] && [ -d "${CATALYST_DSYM}" ]; then
    mkdir -p "${DSYMS_FOLDER}/ios-arm64_x86_64-maccatalyst"
    cp -R "${CATALYST_DSYM}" "${DSYMS_FOLDER}/ios-arm64_x86_64-maccatalyst/"
  fi

  rm -rf "${SIMULATOR_ARCHIVE_PATH}"
  rm -rf "${IOS_DEVICE_ARCHIVE_PATH}"
  if [ "${FRAMEWORK_NAME}" != "CleverPushExtension" ]; then
    rm -rf "${CATALYST_ARCHIVE_PATH}"
  fi
}

create_xcframework "CleverPush"
create_xcframework "CleverPushLocation"
create_xcframework "CleverPushExtension"

open "${WORKING_DIR}"

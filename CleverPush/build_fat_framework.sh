#!/bin/bash
set -e

WORKING_DIR=$(pwd)
DERIVED_DATA_RELATIVE_DIR=temp
BUILD_CONFIG="Debug"
BUILD_TYPE="staticlib"
BUILD_SCHEME="${CLEVERPUSH_TARGET_NAME}"
BUILD_PROJECT="CleverPush.xcodeproj"

# NOTE: Once Apple drops support for Xcode 10, we can edit this to use same xcodebuild version for all three build commands
XCODEBUILD_OLDEST_SUPPORTED=/Applications/Xcode11.7.app/Contents/Developer/usr/bin/xcodebuild

# For backwards compatible bitcode we need to build iphonesimulator + iphoneos with 3 versions behind the latest.
$XCODEBUILD_OLDEST_SUPPORTED -configuration ${BUILD_CONFIG} MACH_O_TYPE=${BUILD_TYPE} -sdk "iphonesimulator" ARCHS="x86_64 i386" -project ${BUILD_PROJECT} -scheme ${BUILD_SCHEME} SYMROOT="${DERIVED_DATA_RELATIVE_DIR}/"
$XCODEBUILD_OLDEST_SUPPORTED -configuration ${BUILD_CONFIG} MACH_O_TYPE=${BUILD_TYPE} -sdk "iphoneos" ARCHS="armv7 armv7s arm64 arm64e"  -project ${BUILD_PROJECT} -scheme ${BUILD_SCHEME} SYMROOT="${DERIVED_DATA_RELATIVE_DIR}/"

USER=$(id -un)
DERIVED_DATA_CLEVERPUSH_DIR="${WORKING_DIR}/${DERIVED_DATA_RELATIVE_DIR}"

# Use Debug configuration to expose symbols
SIMULATOR_DIR="${DERIVED_DATA_CLEVERPUSH_DIR}/Debug-iphonesimulator"
IPHONE_DIR="${DERIVED_DATA_CLEVERPUSH_DIR}/Debug-iphoneos"

SIMULATOR_OUTPUT_DIR=${SIMULATOR_DIR}/${CLEVERPUSH_OUTPUT_NAME}.framework
IPHONE_OUTPUT_DIR=${IPHONE_DIR}/${CLEVERPUSH_OUTPUT_NAME}.framework

UNIVERSAL_DIR=${DERIVED_DATA_CLEVERPUSH_DIR}/Debug-universal
FINAL_FRAMEWORK=${UNIVERSAL_DIR}/${CLEVERPUSH_OUTPUT_NAME}.framework

rm -rf "${UNIVERSAL_DIR}"
mkdir "${UNIVERSAL_DIR}"

echo "> Making Final CleverPush with all Architecture. iOS, iOS Simulator(x86_64)"
lipo -create -output "$UNIVERSAL_DIR"/${CLEVERPUSH_OUTPUT_NAME} "${IPHONE_OUTPUT_DIR}"/${CLEVERPUSH_OUTPUT_NAME} "${SIMULATOR_OUTPUT_DIR}"/${CLEVERPUSH_OUTPUT_NAME}

echo "> Copying Framework Structure to Universal Output Directory"
cp -a ${IPHONE_OUTPUT_DIR} ${UNIVERSAL_DIR}

cd $UNIVERSAL_DIR
echo "> Moving CleverPush fat binary to Final Framework"
mv ${CLEVERPUSH_OUTPUT_NAME} ${CLEVERPUSH_OUTPUT_NAME}.framework

cd $FINAL_FRAMEWORK

declare -a files=("Headers" "Modules" "${CLEVERPUSH_OUTPUT_NAME}")

# Create the Versions folders
mkdir Versions
mkdir Versions/A
mkdir Versions/A/Resources

# Move the framework files/folders
for name in "${files[@]}"; do
   mv ${name} Versions/A/${name}
done

# Create symlinks at the root of the framework
for name in "${files[@]}"; do
   ln -s Versions/A/${name} ${name}
done

# move info.plist into Resources and create appropriate symlinks
mv Info.plist Versions/A/Resources/Info.plist
#mv AppBanner.storyboard Versions/A/Resources/AppBanner.storyboard
ln -s Versions/A/Resources Resources

# Create a symlink directory for 'Versions/A' called 'Current'
cd Versions
ln -s A Current

RELEASE_OUTPUT_FRAMEWORK_DIR="${WORKING_DIR}/Framework/${CLEVERPUSH_OUTPUT_NAME}.framework"

# Copy the built product to the final destination in {repo}/CleverPush/Framework
rm -rf "${WORKING_DIR}/Framework/${CLEVERPUSH_OUTPUT_NAME}.framework"
cp -a "${FINAL_FRAMEWORK}" "${WORKING_DIR}/Framework/${CLEVERPUSH_OUTPUT_NAME}.framework"

echo "Listing frameworks of final framework"
file "${RELEASE_OUTPUT_FRAMEWORK_DIR}/Versions/A/${CLEVERPUSH_OUTPUT_NAME}"
ls -l "${RELEASE_OUTPUT_FRAMEWORK_DIR}/Versions/A/${CLEVERPUSH_OUTPUT_NAME}"

echo "Opening final release framework in Finder:${WORKING_DIR}/Framework/${CLEVERPUSH_OUTPUT_NAME}.framework"
open "${WORKING_DIR}/Framework"

echo "Done"

#!/bin/bash

# https://github.com/ryangball/chrome-enable-autoupdates/blob/master/chrome-enable-autoupdates.sh

# This script enables system wide automatic updates for Google Chrome.

# Written by Ryan Ball after somehow becoming responsible for it

# Spawned from this thread: https://www.jamf.com/jamf-nation/discussions/23323/how-to-update-chrome-automatically

# Bash version of this script (which I also contributed a tiny piece to):
#   https://github.com/hjuutilainen/adminscripts/blob/master/chrome-enable-autoupdates.py

chromePath="/Applications/Google Chrome.app"
chromeVersion=$(/usr/bin/defaults read "$chromePath/Contents/Info.plist" CFBundleShortVersionString)
chromeMajorVersion=$(/usr/bin/awk -F '.' '{print $1}' <<< "$chromeVersion")
updateURL=$(/usr/bin/defaults read "$chromePath/Contents/Info.plist" KSUpdateURL)
productID=$(/usr/bin/defaults read "$chromePath/Contents/Info.plist" KSProductID)
exitCode="0"

# Check if Chrome is installed
if [[ ! -e "$chromePath" ]]; then
    echo "Error: $chromePath not found"
    exit 1
fi

# Determine KeystoneRegistration.framework path
if [[ $chromeMajorVersion -ge 75 ]] ; then
    frameworkPath="$chromePath/Contents/Frameworks/Google Chrome Framework.framework/Versions/Current/Frameworks/KeystoneRegistration.framework"
else
    frameworkPath="$chromePath/Contents/Versions/$chromeVersion/Google Chrome Framework.framework/Versions/A/Frameworks/KeystoneRegistration.framework"
fi

# Check if framework exists
if [[ ! -e "$frameworkPath" ]]; then
    echo "Error: KeystoneRegistration.framework not found"
    exit 1
fi

# Determine ksinstall path
if [[ $chromeMajorVersion -ge 80 ]] ; then
  ksinstallPath="$frameworkPath/Helpers/ksinstall"
else
  ksinstallPath="$frameworkPath/Resources/ksinstall"
fi

# Install the current Keystone
if ! "$ksinstallPath" --install "$frameworkPath/Resources/Keystone.tbz" --force 2>/dev/null ; then
    exitCode="$?"
    echo "Error: Keystone install failed with code $exitCode"
    exit "$exitCode"
else
    echo "Keystone installed"
fi

# Registers Chrome with Keystone
if ! /Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle/Contents/MacOS/ksadmin \
    --register \
    --productid "$productID" \
    --version "$chromeVersion" \
    --xcpath "$chromePath" \
    --url "$updateURL" \
    --tag-path "$chromePath/Contents/Info.plist" \
    --tag-key "KSChannelID" \
    --brand-path "/Library/Google/Google Chrome Brand.plist" \
    --brand-key "KSBrandID" \
    --version-path "$chromePath/Contents/Info.plist" \
    --version-key "KSVersion"
then
    exitCode="$?"
    echo "Error: Failed to register Chrome with Keystone - code $exitCode"
    exit "$exitCode"
else
    echo "Registered Chrome with Keystone"
fi

exit 0

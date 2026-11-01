#!/bin/bash
# Builds the Xcode project and opens it. Safe to run again any time.
set -e
cd "$(dirname "$0")"

# 1. A unique app ID just for you (Apple requires one). Saved so it never changes.
if [ ! -f .bundle-prefix ]; then
  NAME=$(whoami | tr -cd 'a-zA-Z0-9' | tr 'A-Z' 'a-z')
  RAND=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5)
  echo "com.${NAME}${RAND}" > .bundle-prefix
fi
export BUNDLE_PREFIX=$(cat .bundle-prefix)
echo "App ID: ${BUNDLE_PREFIX}.sleeponit"

# If Xcode has already set up your signing certificate, reuse your team automatically
# (so re-running this script doesn't make you re-pick it in Xcode).
export DEVELOPMENT_TEAM=$(security find-certificate -c "Apple Development" -p 2>/dev/null \
  | openssl x509 -noout -subject 2>/dev/null \
  | sed -n 's/.*OU *= *\([A-Z0-9]\{10\}\).*/\1/p' | head -1)

# 2. Get XcodeGen (a small free tool that writes the Xcode project file).
XCODEGEN=$(command -v xcodegen || true)
if [ -z "$XCODEGEN" ]; then
  if [ ! -x .tools/xcodegen/bin/xcodegen ]; then
    echo "Downloading XcodeGen…"
    mkdir -p .tools
    curl -fsSL -o .tools/xcodegen.zip https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip
    unzip -oq .tools/xcodegen.zip -d .tools
  fi
  XCODEGEN=.tools/xcodegen/bin/xcodegen
fi

# 3. Generate and open.
"$XCODEGEN" generate
echo ""
echo "Done! Opening Xcode…"
open SleepOnIt.xcodeproj

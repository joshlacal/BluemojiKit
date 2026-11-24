#!/usr/bin/env bash
# Builds the DocC site for BluemojiKit into ./_site, ready for GitHub Pages
# (https://joshlacal.github.io/BluemojiKit/). The same script runs in CI and locally.
set -euo pipefail
cd "$(dirname "$0")/.."

SCHEME="BluemojiKit"
MODULE="bluemojikit"
BASE_PATH="BluemojiKit"
DEST='generic/platform=macOS'
export PETREL_LOCAL_INTEGRATION=0  # resolve dependencies from their remotes, as CI does

rm -r .build/docs _site 2>/dev/null || true
xcodebuild docbuild -scheme "$SCHEME" -destination "$DEST" \
  -derivedDataPath .build/docs -skipPackagePluginValidation

archive=$(find .build/docs -name "$SCHEME.doccarchive" -type d | head -1)
test -n "$archive" || { echo "no $SCHEME.doccarchive found" >&2; exit 1; }

xcrun docc process-archive transform-for-static-hosting "$archive" \
  --output-path _site --hosting-base-path "$BASE_PATH"

cat > _site/index.html <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>$SCHEME documentation</title>
<link rel="canonical" href="documentation/$MODULE/">
<meta http-equiv="refresh" content="0; url=documentation/$MODULE/">
</head>
<body><p><a href="documentation/$MODULE/">$SCHEME documentation</a></p></body>
</html>
HTML
touch _site/.nojekyll

test -f "_site/documentation/$MODULE/index.html"
test -f "_site/data/documentation/$MODULE.json"
echo "Site ready in _site/"

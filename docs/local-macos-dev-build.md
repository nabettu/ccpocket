# Local macOS build without the maintainer's signing team (fork use)

`flutter build macos` fails on machines outside the maintainer's Apple team:
`No profiles for 'com.k9i.ccpocket' were found`. Passing `CODE_SIGN_IDENTITY=-`
alone does not help ("Runner requires a provisioning profile"). Build unsigned,
then sign ad hoc.

Use a separate bundle id (`com.k9i.ccpocket.dev`). An ad-hoc signed app with the
release bundle id would share the sandbox container of the installed
`/Applications/CC Pocket.app` under a different signature. The trade-off is that
the dev build starts with no machines configured.

```bash
cd apps/mobile
FLUTTER=~/.local/share/ccpocket/flutter/bin/flutter   # Dart ^3.13; Homebrew flutter is too old
DD=/tmp/ccpocket-macos-dd
$FLUTTER build macos --debug --config-only
(cd macos && xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -configuration Debug -derivedDataPath "$DD" \
  PRODUCT_BUNDLE_IDENTIFIER=com.k9i.ccpocket.dev \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build)

# Sandbox entitlements without the team-bound keychain access group
sed 's/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.k9i.ccpocket.dev/g' \
  macos/Runner/DebugProfile.entitlements > /tmp/dev.entitlements
/usr/libexec/PlistBuddy -c "Delete :keychain-access-groups" /tmp/dev.entitlements

APP="$DD/Build/Products/Debug/CC Pocket.app"
codesign --force --deep -s - "$APP"
codesign --force -s - --entitlements /tmp/dev.entitlements "$APP"
open -n "$APP"
```

The debug build runs standalone (no `flutter run` attached).

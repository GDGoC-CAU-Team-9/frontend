#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"
INFO_PLIST="$PROJECT_ROOT/ios/Runner/Info.plist"
PUBSPEC_FILE="$PROJECT_ROOT/pubspec.yaml"
ERROR_COUNT=0

pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
warn() { echo "[WARN] $1"; }

echo "== iOS Release Preflight =="

if [[ ! -f "$ENV_FILE" ]]; then
  fail ".env file not found at $ENV_FILE"
fi

if [[ -f "$ENV_FILE" ]]; then
  BASE_URL_LINE="$(grep -E '^[[:space:]]*BASE_URL=' "$ENV_FILE" | head -n1 || true)"
  if [[ -z "$BASE_URL_LINE" ]]; then
    fail "BASE_URL is missing in .env"
  else
    BASE_URL="${BASE_URL_LINE#*=}"
    BASE_URL="${BASE_URL#"${BASE_URL%%[![:space:]]*}"}"
    BASE_URL="${BASE_URL%"${BASE_URL##*[![:space:]]}"}"

    if [[ "$BASE_URL" != https://* ]]; then
      fail "BASE_URL must start with https:// for release. Current: $BASE_URL"
    else
      pass "BASE_URL uses HTTPS ($BASE_URL)"
    fi

    if [[ "$BASE_URL" == *"localhost"* || "$BASE_URL" == *"127.0.0.1"* ]]; then
      fail "Release BASE_URL cannot point to localhost"
    else
      pass "BASE_URL is not localhost"
    fi
  fi
fi

if [[ ! -f "$INFO_PLIST" ]]; then
  fail "Info.plist not found at $INFO_PLIST"
fi

if [[ -f "$INFO_PLIST" ]]; then
  grep -q "NSCameraUsageDescription" "$INFO_PLIST" \
    && pass "NSCameraUsageDescription exists" \
    || fail "NSCameraUsageDescription is missing"

  grep -q "NSPhotoLibraryUsageDescription" "$INFO_PLIST" \
    && pass "NSPhotoLibraryUsageDescription exists" \
    || fail "NSPhotoLibraryUsageDescription is missing"
fi

for lang in en ko es fr ja zh; do
  f="$PROJECT_ROOT/ios/Runner/$lang.lproj/InfoPlist.strings"
  [[ -f "$f" ]] \
    && pass "Localized InfoPlist strings exist for $lang" \
    || fail "Missing localized InfoPlist.strings for $lang"
done

if [[ ! -f "$PUBSPEC_FILE" ]]; then
  fail "pubspec.yaml not found at $PUBSPEC_FILE"
fi

if [[ -f "$PUBSPEC_FILE" ]]; then
  VERSION_LINE="$(grep -E '^version:' "$PUBSPEC_FILE" | head -n1 || true)"
  if [[ -z "$VERSION_LINE" ]]; then
    fail "version is missing in pubspec.yaml"
  else
    VERSION_VALUE="$(echo "$VERSION_LINE" | awk '{print $2}')"
    if [[ ! "$VERSION_VALUE" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
      fail "version format must be x.y.z+build. Current: $VERSION_VALUE"
    else
      BUILD_NUMBER="${VERSION_VALUE##*+}"
      if [[ "$BUILD_NUMBER" -lt 1 ]]; then
        fail "build number must be >= 1. Current: $BUILD_NUMBER"
      else
        pass "pubspec version format is valid ($VERSION_VALUE)"
      fi
    fi
  fi
fi

DIO_CLIENT_FILE="$PROJECT_ROOT/lib/core/network/dio_client.dart"
if ! grep -q 'LogInterceptor' "$DIO_CLIENT_FILE"; then
  warn "LogInterceptor not found (this may be intentional)"
elif sed '/if (kDebugMode)/,/}/d' "$DIO_CLIENT_FILE" | grep -q 'LogInterceptor'; then
  fail "LogInterceptor exists but is not guarded by kDebugMode"
else
  pass "Network logging is guarded by kDebugMode"
fi

if [[ "$ERROR_COUNT" -gt 0 ]]; then
  echo "Preflight failed with $ERROR_COUNT issue(s)."
  exit 1
fi

echo "All required preflight checks passed."

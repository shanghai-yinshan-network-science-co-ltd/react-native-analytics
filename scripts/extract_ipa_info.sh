#!/bin/bash
# 从 ipas 目录下的每个 IPA 提取 appName, appBundleId, appScheme
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IPAS_DIR="$PROJECT_ROOT/ipas"
EXTRACT_BASE="/tmp/ipa_extract_$$"
mkdir -p "$EXTRACT_BASE"

for ipa in "$IPAS_DIR"/*.ipa; do
  [ -f "$ipa" ] || continue
  name=$(basename "$ipa" .ipa)
  extract_dir="$EXTRACT_BASE/$(echo "$name" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
  mkdir -p "$extract_dir"
  if ! unzip -q -o -d "$extract_dir" "$ipa" 2>/dev/null; then
    echo "SKIP: $name (unzip failed)" >&2
    rm -rf "$extract_dir"
    continue
  fi
  plist=$(find "$extract_dir" -path "*/Payload/*.app/Info.plist" 2>/dev/null | head -1)
  if [ -z "$plist" ]; then
    echo "SKIP: $name (no Info.plist)" >&2
    rm -rf "$extract_dir"
    continue
  fi
  bundleId=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist" 2>/dev/null)
  appName=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Print :CFBundleName" "$plist" 2>/dev/null)
  # 取第一个 URL Scheme；若无则尝试 LSApplicationQueriesSchemes
  appScheme=$(/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$plist" 2>/dev/null)
  if [ -z "$appScheme" ]; then
    appScheme=$(/usr/libexec/PlistBuddy -c "Print :LSApplicationQueriesSchemes:0" "$plist" 2>/dev/null)
  fi
  if [ -n "$appScheme" ]; then
    # 确保 scheme 带 ://
    case "$appScheme" in
      *://) ;;
      *) appScheme="${appScheme}://" ;;
    esac
  fi
  echo "appName=$appName|appBundleId=$bundleId|appScheme=$appScheme"
  rm -rf "$extract_dir"
done
rm -rf "$EXTRACT_BASE"

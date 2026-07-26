#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <project-root> <output-markdown>" >&2
  exit 64
fi

project_root="$(cd "$1" && pwd)"
output_path="$2"

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep (rg) is required." >&2
  exit 69
fi

swift_count="$(
  find "$project_root" \
    \( -name .git -o -name .derivedData -o -name DerivedData -o -name build \) -prune -o \
    -type f -name '*.swift' -print |
    wc -l | tr -d ' '
)"
manifest_count="$(
  find "$project_root" \
    \( -name .git -o -name .derivedData -o -name DerivedData -o -name build \) -prune -o \
    -type f \( -name '*.plist' -o -name '*.xcprivacy' \) -print |
    wc -l | tr -d ' '
)"
privacy_manifest_count="$(
  find "$project_root" \
    \( -name .git -o -name .derivedData -o -name DerivedData -o -name build \) -prune -o \
    -type f -name '*.xcprivacy' -print |
    wc -l | tr -d ' '
)"

if [[ "$swift_count" -eq 0 ]]; then
  echo "No Swift source files were found under: $project_root" >&2
  exit 66
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/irochigai-privacy.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

scan() {
  local pattern="$1"
  local destination="$2"
  rg --line-number --hidden --glob '!**/.git/**' --glob '!**/.derivedData/**' \
    --glob '!**/DerivedData/**' --glob '!**/build/**' --glob '!**/deliverables/**' \
    --glob '*.swift' --glob '*.plist' --glob '*.xcprivacy' --glob 'project.yml' --glob 'Package.swift' \
    --glob 'Podfile' --glob 'Cartfile' --glob '*.pbxproj' \
    "$pattern" "$project_root" >"$destination" || true
}

scan 'NS(Camera|Microphone|Location|Contacts|PhotoLibrary|Calendars|Reminders|Bluetooth|Motion|FaceID|Health|Tracking)[A-Za-z]*UsageDescription' "$work_dir/permissions.txt"
scan 'URLSession|URLRequest|WKWebView|SFSafariViewController|NWConnection|Network\.framework|https?://' "$work_dir/network.txt"
grep -v 'www\.apple\.com/DTDs/PropertyList-1\.0\.dtd' "$work_dir/network.txt" >"$work_dir/network.filtered.txt" || true
mv "$work_dir/network.filtered.txt" "$work_dir/network.txt"
scan 'XCRemoteSwiftPackageReference|XCSwiftPackageProductDependency|https://github\.com/|^[[:space:]]*pod[[:space:]]|^[[:space:]]*github[[:space:]]' "$work_dir/dependencies.txt"
scan '@AppStorage|UserDefaults|SwiftData|CoreData|NSPersistent|Keychain|SecItem|FileManager|write\(to:' "$work_dir/persistence.txt"
scan 'UIPasteboard|AVCapture|CLLocation|CNContact|ATTrackingManager|AdSupport|ASIdentifierManager|SecItem|PHPhotoLibrary' "$work_dir/sensitive.txt"
rg --line-number --hidden --glob '!**/.git/**' --glob '!**/.derivedData/**' \
  --glob '!**/DerivedData/**' --glob '!**/build/**' --glob '*.swift' \
  '@AppStorage|UserDefaults' "$project_root" >"$work_dir/user-defaults-source.txt" || true
rg --line-number --hidden --glob '!**/.git/**' --glob '!**/.derivedData/**' \
  --glob '!**/DerivedData/**' --glob '!**/build/**' --glob '*.xcprivacy' \
  'NSPrivacyAccessedAPICategoryUserDefaults' "$project_root" >"$work_dir/user-defaults-category.txt" || true
rg --line-number --hidden --glob '!**/.git/**' --glob '!**/.derivedData/**' \
  --glob '!**/DerivedData/**' --glob '!**/build/**' --glob '*.xcprivacy' \
  'NSPrivacyAccessedAPITypeReasons' "$project_root" >"$work_dir/required-reason-keys.txt" || true

count_lines() {
  awk 'END { print NR + 0 }' "$1"
}

permission_count="$(count_lines "$work_dir/permissions.txt")"
network_count="$(count_lines "$work_dir/network.txt")"
dependency_count="$(count_lines "$work_dir/dependencies.txt")"
persistence_count="$(count_lines "$work_dir/persistence.txt")"
sensitive_count="$(count_lines "$work_dir/sensitive.txt")"
user_defaults_source_count="$(count_lines "$work_dir/user-defaults-source.txt")"
user_defaults_category_count="$(count_lines "$work_dir/user-defaults-category.txt")"
required_reason_key_count="$(count_lines "$work_dir/required-reason-keys.txt")"

required_reason_status='N/A'
if [[ "$user_defaults_source_count" -gt 0 ]]; then
  if [[ "$privacy_manifest_count" -eq 0 || "$user_defaults_category_count" -eq 0 || "$required_reason_key_count" -eq 0 ]]; then
    required_reason_status='BLOCKER'
  else
    required_reason_status='REVIEW'
  fi
fi

mkdir -p "$(dirname "$output_path")"

{
  echo '# iOS Privacy & Security Static Scan'
  echo
  echo "- Project root: \`$project_root\`"
  echo "- Swift files scanned: $swift_count"
  echo "- Property lists and privacy manifests scanned: $manifest_count"
  echo "- Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo
  echo '## Summary'
  echo
  echo '| Area | Matches | Interpretation |'
  echo '|---|---:|---|'
  echo "| Permission declarations | $permission_count | Review every usage-description key |"
  echo "| Network and web APIs | $network_count | Zero supports, but does not prove, an offline claim |"
  echo "| External dependencies | $dependency_count | Project-file declarations may include Xcode boilerplate |"
  echo "| Persistence APIs | $persistence_count | Confirm only intended local values are stored |"
  echo "| UserDefaults required-reason gate | $required_reason_status | Uses: $user_defaults_source_count; privacy manifests: $privacy_manifest_count; category entries: $user_defaults_category_count; reason keys: $required_reason_key_count |"
  echo "| Sensitive APIs | $sensitive_count | Review camera, location, contacts, tracking, pasteboard, and keychain access |"
  echo

  for section in permissions network dependencies persistence sensitive; do
    case "$section" in
      permissions) heading='Permission declarations' ;;
      network) heading='Network and web APIs' ;;
      dependencies) heading='Dependency declarations' ;;
      persistence) heading='Persistence APIs' ;;
      sensitive) heading='Sensitive APIs' ;;
    esac
    echo "## $heading"
    echo
    if [[ -s "$work_dir/$section.txt" ]]; then
      echo '```text'
      sed "s#${project_root}/##" "$work_dir/$section.txt"
      echo '```'
    else
      echo 'No static matches.'
    fi
    echo
  done

  echo '## UserDefaults required-reason API gate'
  echo
  if [[ "$user_defaults_source_count" -eq 0 ]]; then
    echo 'No `UserDefaults` or `@AppStorage` source match; this gate is not applicable.'
  elif [[ "$required_reason_status" == 'BLOCKER' ]]; then
    echo '**BLOCKER:** `UserDefaults` or `@AppStorage` is used, but a privacy manifest, the UserDefaults accessed-API category, or an accessed-API reasons key is missing. Do not claim App Store readiness.'
  else
    echo '**REVIEW:** A UserDefaults category and reasons key are present. Verify that every declared reason code matches the actual access boundary before claiming App Store readiness.'
  fi
  echo
  echo "Source uses: $user_defaults_source_count"
  echo
  if [[ -s "$work_dir/user-defaults-source.txt" ]]; then
    echo '```text'
    sed "s#${project_root}/##" "$work_dir/user-defaults-source.txt"
    echo '```'
  fi
  echo
  echo "UserDefaults category entries: $user_defaults_category_count"
  echo
  if [[ -s "$work_dir/user-defaults-category.txt" ]]; then
    echo '```text'
    sed "s#${project_root}/##" "$work_dir/user-defaults-category.txt"
    echo '```'
  fi
  echo

  echo '## Claim gate'
  echo
  if [[ "$network_count" -eq 0 && "$permission_count" -eq 0 && "$dependency_count" -eq 0 ]]; then
    echo 'Static evidence is consistent with a local-only app that requests no protected-resource permission and declares no external package.'
  else
    echo 'Do not claim “offline / no permissions / no external SDK” until every match above is explained.'
  fi
  if [[ "$required_reason_status" == 'BLOCKER' ]]; then
    echo
    echo 'App Store readiness is blocked by the missing or incomplete required-reason API declaration.'
  fi
  echo
  echo '## Limitations'
  echo
  echo 'This is pattern-based static analysis, not runtime traffic inspection, binary dependency analysis, entitlement review, or a penetration test. Review the built target, entitlements, and App Privacy answers separately.'
} >"$output_path"

echo "Wrote privacy scan: $output_path"
echo "permissions=$permission_count network=$network_count dependencies=$dependency_count persistence=$persistence_count sensitive=$sensitive_count required_reason=$required_reason_status"

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

swift_count="$(find "$project_root" -type f -name '*.swift' | wc -l | tr -d ' ')"
plist_count="$(find "$project_root" -type f -name '*.plist' | wc -l | tr -d ' ')"

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
    --glob '*.swift' --glob '*.plist' --glob 'project.yml' --glob 'Package.swift' \
    --glob 'Podfile' --glob 'Cartfile' --glob '*.pbxproj' \
    "$pattern" "$project_root" >"$destination" || true
}

scan 'NS(Camera|Microphone|Location|Contacts|PhotoLibrary|Calendars|Reminders|Bluetooth|Motion|FaceID|Health|Tracking)[A-Za-z]*UsageDescription' "$work_dir/permissions.txt"
scan 'URLSession|URLRequest|WKWebView|SFSafariViewController|NWConnection|Network\.framework|https?://' "$work_dir/network.txt"
scan 'Package\.swift|XCRemoteSwiftPackageReference|packageProductDependencies|Podfile|Cartfile|Carthage|CocoaPods' "$work_dir/dependencies.txt"
scan '@AppStorage|UserDefaults|SwiftData|CoreData|NSPersistent|Keychain|SecItem|FileManager|write\\(to:' "$work_dir/persistence.txt"
scan 'UIPasteboard|AVCapture|CLLocation|CNContact|ATTrackingManager|AdSupport|ASIdentifierManager|SecItem|PHPhotoLibrary' "$work_dir/sensitive.txt"

count_lines() {
  awk 'END { print NR + 0 }' "$1"
}

permission_count="$(count_lines "$work_dir/permissions.txt")"
network_count="$(count_lines "$work_dir/network.txt")"
dependency_count="$(count_lines "$work_dir/dependencies.txt")"
persistence_count="$(count_lines "$work_dir/persistence.txt")"
sensitive_count="$(count_lines "$work_dir/sensitive.txt")"

mkdir -p "$(dirname "$output_path")"

{
  echo '# iOS Privacy & Security Static Scan'
  echo
  echo "- Project root: \`$project_root\`"
  echo "- Swift files scanned: $swift_count"
  echo "- Property lists scanned: $plist_count"
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

  echo '## Claim gate'
  echo
  if [[ "$network_count" -eq 0 && "$permission_count" -eq 0 && "$dependency_count" -eq 0 ]]; then
    echo 'Static evidence is consistent with a local-only app that requests no protected-resource permission and declares no external package.'
  else
    echo 'Do not claim “offline / no permissions / no external SDK” until every match above is explained.'
  fi
  echo
  echo '## Limitations'
  echo
  echo 'This is pattern-based static analysis, not runtime traffic inspection, binary dependency analysis, entitlement review, or a penetration test. Review the built target, entitlements, and App Privacy answers separately.'
} >"$output_path"

echo "Wrote privacy scan: $output_path"
echo "permissions=$permission_count network=$network_count dependencies=$dependency_count persistence=$persistence_count sensitive=$sensitive_count"

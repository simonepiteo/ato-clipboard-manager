#!/bin/zsh

# Shared by the app, DMG, and release scripts. Contains no private key material.
ato_resolve_signing_identity() {
  local local_identity
  local_identity="$(/usr/bin/security find-identity -v -p codesigning |
    /usr/bin/awk '/"ATO Local Code Signing"$/ { print $2 }')"

  if [[ "$local_identity" == *$'\n'* ]]; then
    if [[ -n "${CODE_SIGN_IDENTITY:-}" &&
          $'\n'"$local_identity"$'\n' == *$'\n'"$CODE_SIGN_IDENTITY"$'\n'* ]]; then
      local_identity="$CODE_SIGN_IDENTITY"
    elif [[ -z "${CODE_SIGN_IDENTITY:-}" || "$CODE_SIGN_IDENTITY" == "ATO Local Code Signing" ]]; then
      print -u2 "Multiple ATO Local Code Signing identities were found. Set CODE_SIGN_IDENTITY to the intended certificate fingerprint."
      return 1
    else
      local_identity=""
    fi
  fi

  if [[ -z "${CODE_SIGN_IDENTITY:-}" ]]; then
    if [[ -z "$local_identity" ]]; then
      print -u2 "No stable signing identity is available. Run ./scripts/setup-local-signing.sh or set CODE_SIGN_IDENTITY."
      print -u2 "For a temporary ad-hoc build only, explicitly set CODE_SIGN_IDENTITY=-. Accessibility permission may be lost after rebuilding."
      return 1
    fi
    export CODE_SIGN_IDENTITY="$local_identity"
  fi

  ATO_LOCAL_SIGNING=false
  ATO_SIGNING_TIMESTAMP="--timestamp"
  if [[ "$CODE_SIGN_IDENTITY" == "ATO Local Code Signing" ||
        ( -n "$local_identity" && "$CODE_SIGN_IDENTITY" == "$local_identity" ) ]]; then
    [[ -n "$local_identity" ]] || {
      print -u2 "ATO Local Code Signing is unavailable or not trusted for code signing."
      return 1
    }
    export CODE_SIGN_IDENTITY="$local_identity"
    ATO_LOCAL_SIGNING=true
    ATO_SIGNING_TIMESTAMP="--timestamp=none"
  elif [[ "$CODE_SIGN_IDENTITY" == "-" ]]; then
    ATO_SIGNING_TIMESTAMP="--timestamp=none"
  fi
}

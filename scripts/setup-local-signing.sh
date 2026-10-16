#!/bin/zsh

set -euo pipefail
umask 077

PROJECT_ROOT="${0:A:h:h}"
IDENTITY_NAME="ATO Local Code Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if /usr/bin/security find-identity -v -p codesigning |
   /usr/bin/awk '/"ATO Local Code Signing"$/ { found=1 } END { exit !found }'; then
  print "ATO Local Code Signing is already configured; keeping the existing identity."
  exit 0
fi

if /usr/bin/security find-certificate -c "$IDENTITY_NAME" "$KEYCHAIN" >/dev/null 2>&1; then
  print -u2 "An ATO certificate already exists but is not a usable signing identity."
  print -u2 "Restore its private key or code-signing trust in Keychain Access; do not regenerate it, because that changes the app identity."
  exit 1
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ato-local-signing.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

cat > "$TEMP_DIR/certificate.cnf" <<'CONFIG'
[req]
distinguished_name = subject
x509_extensions = extensions
prompt = no

[subject]
CN = ATO Local Code Signing

[extensions]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
CONFIG

/usr/bin/openssl req -new -x509 -newkey rsa:3072 -sha256 -nodes -days 3650 \
  -config "$TEMP_DIR/certificate.cnf" \
  -keyout "$TEMP_DIR/private-key.pem" -out "$TEMP_DIR/certificate.pem" \
  2> "$TEMP_DIR/openssl.log"

# Only codesign is pre-authorized to use this key; no all-applications ACL.
/usr/bin/openssl rsa -in "$TEMP_DIR/private-key.pem" -out "$TEMP_DIR/import-key.pem" \
  2>> "$TEMP_DIR/openssl.log"
/usr/bin/security import "$TEMP_DIR/import-key.pem" -k "$KEYCHAIN" \
  -t priv -f openssl -T /usr/bin/codesign
/usr/bin/security add-trusted-cert -r trustRoot -p codeSign \
  -k "$KEYCHAIN" "$TEMP_DIR/certificate.pem"

source "$PROJECT_ROOT/scripts/code-signing.sh"
ato_resolve_signing_identity
[[ "$ATO_LOCAL_SIGNING" == true ]] || {
  print -u2 "The local identity could not be verified."
  exit 1
}
print "ATO Local Code Signing is ready. The private key is stored in your login keychain."
print "Keep this identity for future builds. Back it up securely using Keychain Access before moving to another Mac."

#!/bin/zsh
# Creates (once) a self-signed code signing certificate,
# "HeadlessGlow local signing", in the login keychain.
#
# Why: with an ad hoc signature, the app's identity is the exact hash of the
# binary, which changes on every build, so macOS forgets the Input Monitoring
# permission. Signed with this certificate, the identity stays stable and
# the permission survives updates.
#
# The certificate is only valid on this Mac and only `codesign` can use its
# key. To remove it: security delete-identity -c "HeadlessGlow local signing"
set -euo pipefail

source "${0:A:h}/lang.zsh"
NAME="HeadlessGlow local signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$NAME" "$KEYCHAIN" >/dev/null 2>&1; then
    say "✓ certificat « $NAME » déjà présent" "✓ certificate “$NAME” already present"
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT   # the private key doesn't stay on disk

cat > "$TMP/cert.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
EOF

/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$TMP/cert.cnf" \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" 2>/dev/null
PASS=$(/usr/bin/openssl rand -hex 16)
/usr/bin/openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -name "$NAME" \
    -out "$TMP/identity.p12" -passout "pass:$PASS"
security import "$TMP/identity.p12" -k "$KEYCHAIN" -P "$PASS" -T /usr/bin/codesign >/dev/null

say "✓ certificat « $NAME » créé dans le trousseau de session" "✓ certificate “$NAME” created in the login keychain"

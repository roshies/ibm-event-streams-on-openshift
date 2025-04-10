#!/bin/bash

# Prompt for input
echo "Enter the Common Name (CN) for the certificate:"
read CN

echo "Enter Subject Alternative Names (SAN), comma-separated (e.g., DNS.1=example.com,DNS.2=example.org):"
read SAN_INPUT

export CANAME=CA
export MYCERT=$(echo $CN | sed 's/\*/wildcard/g' | sed 's/\./_/g')

# Create CSR and Key
openssl req -new -nodes -out $MYCERT.csr -newkey rsa:2048 -keyout $MYCERT.key \
  -subj "/CN=$CN" \
  -addext "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment" \
  -addext "extendedKeyUsage = serverAuth, clientAuth" \
  -days 720

# Generate v3.ext file dynamically
cat > $MYCERT.v3.ext << EOF

authorityKeyIdentifier=keyid,issuer

keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment

extendedKeyUsage = serverAuth, clientAuth

basicConstraints=critical,CA:FALSE

subjectAltName = @alt_names

[alt_names]
$(echo "$SAN_INPUT" | tr ',' '\n')
EOF

# Sign the certificate
openssl x509 -req -in $MYCERT.csr -CA $CANAME.crt -CAkey $CANAME.key -CAcreateserial -out $MYCERT.crt -days 720 -sha256 -extfile $MYCERT.v3.ext

echo "Certificate generated: $MYCERT.crt"
